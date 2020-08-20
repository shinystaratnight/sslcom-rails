class Invoice < ApplicationRecord
  include Filterable
  include Sortable
  
  belongs_to :billable, polymorphic: true
  belongs_to :payment, -> { unscope(where: :state) }, class_name: 'Order', foreign_key: :order_id
  has_many   :orders, -> { unscope(where: :state) }, foreign_key: :invoice_id
  
  attr_accessor :credit_reason
   
  PAYMENT_METHODS      = {bp: 'billing_profile', wire: 'wire_transfer', po: 'po_other'}
  PAYMENT_METHODS_TEXT = {bp: 'Billing Profile', wire: 'WireXfer', po: 'PO/Other'}
  STATUS               = %w{pending paid refunded partially_refunded archived}
  DEFAULT_STATUS       = STATUS.dup - ['archived']
  
  before_validation :set_duration, on: :create, if: :payable_invoice?
  before_validation :set_status, on: :create, if: :payable_invoice?
  before_validation :set_default_billing, if: :payable_invoice?
  before_validation :set_address, if: :payable_invoice?
  after_create      :generate_reference_number, if: :payable_invoice?
  after_create      :notify_admin_billing, if: :payable_invoice?
  
  validates :first_name, :last_name, :address_1, :country, :city,
    :state, :postal_code, presence: true, unless: :payable_invoice?

  def self.index_filter(params)
    filters                    = {}
    p                          = params
    filters[:status]           = { 'in' => p[:status] } unless p[:status].blank?
    filters[:reference_number] = { 'LIKE' => p[:reference_number] } unless p[:reference_number].blank?
    
    unless p[:start_date_type].blank? || p[:start_date].blank?
      operator = COMPARISON[p[:start_date_type].to_sym]
      filters[:start_date] = { operator => DateTime.parse(p[:start_date]).beginning_of_day }
    end
    
    unless p[:end_date_type].blank? || p[:end_date].blank?
      operator = COMPARISON[p[:end_date_type].to_sym]
      filters[:end_date] = { operator => DateTime.parse(p[:end_date]).end_of_day }
    end
    t = p[:team] 
    if t.present?
      found = SslAccount.where(
        "ssl_slug = ? OR acct_number = ? OR id = ? OR company_name = ?", t, t, t, t
      )
      filters[:billable_id] = { '=' => found.first.id } if found.any?
    end
    result = filter(filters)
    result = result.where("orders.reference_number" => p[:order_ref]) if p[:order_ref].present?
    result
  end
  
  def self.get_invoices_for_select(ssl_account)
    ssl_acct = Invoice.get_team ssl_account
    ssl_acct.invoices
      .map{|mi| ["#{mi.reference_number.upcase} (#{mi.status.gsub('_', ' ')})", mi.reference_number]}
      .insert(0, ['NEW INVOICE', 'new_invoice'])
  end
  
  def self.get_current_invoice(ssl_account)
    if ssl_account.billing_monthly?
      MonthlyInvoice.get_current_invoice ssl_account
    else
      DailyInvoice.get_current_invoice ssl_account
    end
  end
  
  def self.create_invoice_for_team(ssl_account)
    ssl_acct = Invoice.get_team ssl_account
    attrs = { billable_id: ssl_acct.id, billable_type: 'SslAccount' }
    ssl_acct.billing_monthly? ? MonthlyInvoice.create(attrs) : DailyInvoice.create(attrs)
  end
  
  def self.invoice_exists_for_team?(ssl_account)
    ssl_acct = Invoice.get_team ssl_account
    if ssl_account.billing_monthly?
      MonthlyInvoice.invoice_exists? ssl_acct
    else
      DailyInvoice.invoice_exists? ssl_acct
    end
  end
    
  def self.get_or_create_for_team(ssl_account)
    ssl_acct = Invoice.get_team ssl_account
    if Invoice.invoice_exists_for_team?(ssl_acct)
      Invoice.get_current_invoice ssl_acct
    else
      Invoice.create_invoice_for_team ssl_acct
    end
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
    amt = get_amount
    amt = amt.is_a?(Integer) ? amt : amt.cents
    !(paid? || refunded? || partially_refunded? || (amt == 0))
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
  
  def get_type_format
    type.gsub('Invoice', '')
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
      get_amount
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
  
  def get_paid_invoice_amount
    Money.new(payment.cents + payment.get_funded_account_amount)
  end
  
  def get_amount_format
    amt = get_amount
    amt.is_a?(Fixnum) ? Money.new(get_cents).format : amt.format
  end
  
  def get_final_amount
    if %w{paypal stripe authnet}.include?(payment.get_merchant)
      payment.get_total_merchant_amount
    else
      get_cents - payment.get_funded_account_amount - get_voided_cents
    end
  end

  def get_voided_cents
    get_approved_items.where(
      state: %w{fully_refunded partially_refunded}
    ).uniq.pluck(:cents).sum
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
        item:         co.respond_to?(:description_with_tier) ? co.description_with_tier(o) : co.certificate.description['certificate_type'],
        new_domains:  domains[:new_domains_count],
        wildcard:     domains[:wildcard],
        non_wildcard: domains[:non_wildcard]
      }
      final
    end
  end
  
  def invoice_bill_to_str
    target = get_any_address

    if target.is_a?(BillingProfile) || (target.payable_invoice? && !address_blank?)
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
  
  def payable_invoice?
    monthly_invoice? || daily_invoice?
  end
  
  def monthly_invoice?
    is_a?(MonthlyInvoice) || type == 'MonthlyInvoice'
  end
  
  def daily_invoice?
    is_a?(DailyInvoice) || type == 'DailyInvoice'
  end
  
  def notify_invoice_paid(user=nil)
    Assignment.users_can_manage_invoice(billable).each do |u|
      OrderNotifier.payable_invoice_paid(
        user: u, invoice: self, paid_by: user
      ).deliver_now
    end
  end
  
  private

  def fix_missing_certificate_order
    o=Order.where(invoice_id: self.id)
    missing=o.find_all{|order|order.certificate_orders.empty?}.last
    co=CertificateOrder.find_by_ref("ref from the notes in missing")
    missing.line_items.last.update_columns sellable_type: "CertificateOrder",  sellable_id: co.id
  end

  def self.get_team(ssl_account)
    ssl_account.is_a?(Integer) ? SslAccount.find(ssl_account) : ssl_account
  end

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
      last_invoice = if monthly_invoice?
        MonthlyInvoice.last_invoice_for_month(billable.id, self)
      else
        DailyInvoice.last_invoice_for_day(billable.id, self)
      end
      
      ref_parts = last_invoice.reference_number.split('-') if last_invoice
      ref = if last_invoice && ref_parts.count == 4
        sub_ref = ref_parts.pop.to_i + 1
        ref_parts.push(sub_ref)
        ref_parts.join('-')
      elsif last_invoice && ref_parts.count == 3
        "#{last_invoice.reference_number}-1"
      else
        "#{monthly_invoice? ? 'mi' : 'di'}-#{SecureRandom.hex(2)}-#{Time.now.to_i.to_s(32)}"
      end
      
      update_attribute(:reference_number, ref)
    end
  end
  
  def notify_admin_billing
    Assignment.users_can_manage_invoice(billable).each do |u|
      OrderNotifier.payable_invoice_new(user: u, invoice: self).deliver_now
    end if Settings.invoice_notify
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
    self.start_date = monthly_invoice? ? MonthlyInvoice::START_DATE : DailyInvoice::START_DATE
    self.end_date = monthly_invoice? ? MonthlyInvoice::END_DATE : DailyInvoice::END_DATE
  end
  
  def set_status
    self.status = 'pending' if status.blank?
  end
  
  def set_default_billing
    self.default_payment = PAYMENT_METHODS[:bp] if default_payment.blank?
  end
end
