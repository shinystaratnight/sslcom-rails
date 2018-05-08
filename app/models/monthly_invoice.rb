class MonthlyInvoice < Invoice
  belongs_to :billable, polymorphic: true
  belongs_to :payment, -> { unscope(where: :state) }, class_name: 'Order', foreign_key: :order_id
  has_many   :orders, -> { unscope(where: :state) }, foreign_key: :invoice_id
  
  validates :start_date, :end_date, :status, :billable_id, :billable_type, :default_payment, presence: true
  
  before_validation :set_duration, on: :create
  before_validation :set_status, on: :create
  before_validation :set_default_billing
  before_validation :set_address
  after_create      :generate_reference_number
  
  PAYMENT_METHODS      = {bp: 'billing_profile', wire: 'wire_transfer', po: 'po_other'}
  PAYMENT_METHODS_TEXT = {bp: 'Billing Profile', wire: 'WireXfer', po: 'PO/Other'}
  STATUS               = %w{pending paid refunded partially_refunded archived}
  DEFAULT_STATUS       = STATUS.dup - ['archived']
  
  def self.invoice_exists?(ssl_account_id)
    ssl = SslAccount.find ssl_account_id
    ssl && ssl.monthly_invoices
      .where(start_date: DateTime.now.beginning_of_month, status: 'pending').any?
  end
  
  def self.get_current_invoice(ssl_account_id)
    ssl = SslAccount.find ssl_account_id
    if ssl
      ssl.monthly_invoices.order(created_at: :desc)
        .where(start_date: DateTime.now.beginning_of_month, status: 'pending').first
    else
      nil
    end
  end
  
  def self.last_invoice_for_month(ssl_account_id, exclude=nil)
    ssl = SslAccount.find ssl_account_id
    ssl.monthly_invoices.order(created_at: :desc)
      .where(start_date: DateTime.now.beginning_of_month)
      .where.not(id: exclude).first
  end
  
  def self.get_teams_invoices(ssl_account_id)
    ssl = SslAccount.find ssl_account_id
    ssl.monthly_invoices.order(created_at: :desc)
  end
  
  def self.get_invoices_for_select(ssl_account_id)
    MonthlyInvoice.get_teams_invoices(ssl_account_id)
      .map{|mi| ["#{mi.reference_number.upcase} (#{mi.status.gsub('_', ' ')})", mi.reference_number]}
      .insert(0, ['NEW INVOICE', 'new_invoice'])
  end
    
  def archived?
    status == 'archived'
  end
  
  def paid_wire_transfer?
    payment && payment.notes.include?(PAYMENT_METHODS_TEXT[:wire])
  end
  
  def paid_po_other?
    payment && payment.notes.include?(PAYMENT_METHODS_TEXT[:po])
  end
    
  def paid?
    status == 'paid'
  end
  
  def pending?
    status == 'pending'
  end
  
  def refunded?
    status == 'refunded'
  end
  
  def partially_refunded?
    status == 'partially_refunded'
  end

  def show_payment_actions?
    !(paid? || refunded? || partially_refunded?)
  end
  
  def show_refund_actions?
    payment && !(merchant_refunded? || refunded?)
  end

  def max_credit
    amt = if payment && !refunded?
      refunds = get_merchant_refunds
      return 0.0 if (refunds == payment.amount) && (payment.get_funded_account_amount == 0)
      
      if payment.get_merchant == 'other'
        payment.get_funded_account_amount - refunds
      else  
        (payment.make_available_total) - refunds
      end
    else
      0.0
    end
    Money.new(amt)
  end
    
  def merchant_refunded?
    fully_refunded = false
    if payment
      ref_merchant = payment.get_merchant
      if ref_merchant && %{stripe paypal authnet}.include?(ref_merchant)
        order_amount = payment.get_total_merchant_amount
        fully_refunded = (order_amount - get_merchant_refunds) == 0
      end
    end
    fully_refunded
  end
  
  def archive!
    update(status: 'archived')
  end
  
  def full_refund!
    update(status: 'refunded')
  end
  
  def partial_refund!
    update(status: 'partially_refunded')
  end
    
  def get_approved_items
    orders.where(approval: 'approved')
  end
  
  def get_removed_items
    orders.where(approval: 'rejected')
  end
  
  def get_credited_total
    if refunded? && 
      ( (payment.make_available_total - get_merchant_refunds) > get_cents )
      get_cents
    else
      max_credit
    end
  end
  
  def get_merchant_refunds
    payment.refunds.any? ? payment.refunds.pluck(:amount).sum : 0
  end
  
  def get_cents
    get_approved_items.map(&:cents).sum
  end  
  
  def get_amount
    get_approved_items.map(&:amount).sum
  end  
  
  def get_amount_format
    amt = get_amount
    amt.is_a?(Fixnum) ? Money.new(get_cents).format : amt.format
  end
  
  def get_final_amount
    if %w{paypal stripe authnet}.include?(payment.get_merchant)
      payment.get_total_merchant_amount
    else
      get_cents - payment.get_funded_account_amount
    end
  end
  
  def funded_account_credit?
    payment.get_funded_account_amount > 0
  end
  
  def get_final_amount_format
    Money.new(get_final_amount).format
  end
      
  def get_item_descriptions
    orders.inject({}) do |final, o|
      co      = o.certificate_orders.first
      domains = o.get_reprocess_domains
      desc    = if o.invoice_description.blank?
        "Additional #{domains[:non_wildcard]} non-wildcard and #{domains[:wildcard]} wildcard domains for certificate order ##{co.ref}."
      else
        "#{o.invoice_description} For certificate order ##{co.ref}."
      end  
      
      final[o.reference_number] = {
        description:  desc, 
        item:         co.respond_to?(:description_with_tier) ? co.description_with_tier : co.certificate.description['certificate_type'],
        new_domains:  domains[:new_domains_count],
        wildcard:     domains[:wildcard],
        non_wildcard: domains[:non_wildcard]
      }
      final
    end
  end
  
  def invoice_bill_to_str
    target = get_any_address

    if target.is_a?(BillingProfile) || (target.is_a?(MonthlyInvoice) && !address_blank?)
      addr = []
      addr << target.company unless target.company.blank?
      addr << "#{target.first_name} #{target.last_name}"
      addr << target.address_1
      addr << target.address_2 unless target.address_2.blank?
      addr << [target.city, target.state, target.postal_code].compact.join(', ')
      addr << target.country
      addr
    else
      []
    end
  end
  
  private
  
  # IF team has billing profiles, retreive address from "default" profile
  # IF default profile is NOT set, then use last created profile address 
  def get_any_address
    profiles     = billable.billing_profiles
    default      = profiles.any? ? profiles.where(default_profile: true) : []
    last_profile = (profiles.any? && default.any?) ? default.first : nil
    last_profile = profiles.order(created_at: :desc).first unless last_profile
    (address_blank? && !last_profile.nil?) ? last_profile : self
  end
  
  def address_blank?
    address_1.blank? &&
      country.blank? && 
      city.blank? &&
      state.blank? &&
      postal_code.blank?
  end
  
  def generate_reference_number
    if reference_number.blank?
      last_invoice = MonthlyInvoice.last_invoice_for_month(billable.id, self)
      ref_parts    = last_invoice.reference_number.split('-') if last_invoice
      
      ref = if last_invoice && ref_parts.count == 4
        sub_ref = ref_parts.pop.to_i + 1
        ref_parts.push(sub_ref)
        ref_parts.join('-')
      elsif last_invoice && ref_parts.count == 3
        "#{last_invoice.reference_number}-1"
      else
        "mi-#{SecureRandom.hex(2)}-#{Time.now.to_i.to_s(32)}"
      end
      
      update_attribute(:reference_number, ref)
    end
  end
  
  def set_address
    if address_blank?
      target = get_any_address
      if target.is_a?(BillingProfile)
        self.company     = target.company
        self.first_name  = target.first_name
        self.last_name   = target.last_name
        self.address_1   = target.address_1
        self.address_2   = target.address_2
        self.city        = target.city
        self.state       = target.state
        self.postal_code = target.postal_code
        self.country     = target.country
      end
    end
  end
  
  def set_duration
    self.start_date = DateTime.now.beginning_of_month
    self.end_date = DateTime.now.end_of_month
  end
  
  def set_status
    self.status = 'pending'
  end
  
  def set_default_billing
    self.default_payment = PAYMENT_METHODS[:bp] if default_payment.blank?
  end
end