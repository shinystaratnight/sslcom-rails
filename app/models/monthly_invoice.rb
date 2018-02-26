class MonthlyInvoice < Invoice
  belongs_to :billable, polymorphic: true
  belongs_to :payment, class_name: 'Order', foreign_key: 'order_id'
  has_many   :orders, foreign_key: :invoice_id
  
  validates :start_date, :end_date, :status, :billable_id, :billable_type, presence: true
  
  before_validation :set_duration, on: :create
  before_validation :set_status, on: :create
  after_create :generate_reference_number
  
  def self.invoice_exists?(ssl_account_id)
    ssl = SslAccount.find ssl_account_id
    ssl && ssl.monthly_invoices.where(start_date: DateTime.now.beginning_of_month).any?
  end
  
  def self.get_current_invoice(ssl_account_id)
    ssl = SslAccount.find ssl_account_id
    ssl ? ssl.monthly_invoices.where(start_date: DateTime.now.beginning_of_month).first : nil
  end
  
  def paid?
    status == 'paid'
  end
  
  def get_cents
    orders.map(&:cents).sum
  end  
  
  def get_amount
    orders.map(&:amount).sum
  end  
  
  def get_amount_format
     get_amount.format
  end  
    
  def get_item_descriptions
    orders.inject({}) do |final, o|
      co           = o.certificate_orders.first
      cur_domains  = co.certificate_contents.find_by(ref: o.notes.split.last.delete(')')).domains
      new_domains  = cur_domains - co.certificate_contents.first.domains
      non_wildcard = new_domains.map {|d| d if !d.include?('*')}.compact
      wildcard     = new_domains.map {|d| d if d.include?('*')}.compact
      
      final[o.reference_number] = {
        description:  "Additional #{non_wildcard.count} non-wildcard and #{wildcard.count} wildcard domains for certificate order #{co.ref}.",
        item:         co.respond_to?(:description_with_tier) ? co.description_with_tier : co.certificate.description['certificate_type'],
        new_domains:  new_domains,
        wildcard:     wildcard,
        non_wildcard: non_wildcard
      }
      final
    end
  end
  
  def invoice_bill_to_str
    last_profile = billable.billing_profiles.order(created_at: :desc).first
    target = (address_blank? && !last_profile.nil?) ? last_profile : self

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
  
  def address_blank?
    address_1.blank? &&
      country.blank? && 
      city.blank? &&
      state.blank? &&
      postal_code.blank?
  end
  
  def generate_reference_number
    if reference_number.blank?
      update_attribute(
        :reference_number, "i-#{SecureRandom.hex(2)}-#{Time.now.to_i.to_s(32)}"
      )
    end
  end
  
  def set_duration
    self.start_date = DateTime.now.beginning_of_month
    self.end_date = DateTime.now.end_of_month
  end
  
  def set_status
    self.status = 'pending'
  end
end