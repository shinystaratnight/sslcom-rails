class MonthlyInvoice < Invoice
  belongs_to :billable, polymorphic: true
  has_many   :orders, foreign_key: :invoice_id
  
  validates :start_date, :end_date, :status, :billable_id, :billable_type, presence: true
  
  before_validation :set_duration
  before_validation :set_status
  after_create :generate_reference_number
  
  def self.invoice_exists?(ssl_account_id)
    ssl = SslAccount.find ssl_account_id
    ssl && ssl.monthly_invoices.where(start_date: DateTime.now.beginning_of_month)
  end
  
  def self.get_current_invoice(ssl_account_id)
    ssl = SslAccount.find ssl_account_id
    ssl ? ssl.monthly_invoices.where(start_date: DateTime.now.beginning_of_month).first : nil
  end
  
  private
  
  def generate_reference_number
    update_attribute(
      :reference_number, "i-#{SecureRandom.hex(2)}-#{Time.now.to_i.to_s(32)}"
    )
  end
  
  def set_duration
    self.start_date = DateTime.now.beginning_of_month
    self.end_date = DateTime.now.end_of_month
  end
  
  def set_status
    self.status = 'pending'
  end
end