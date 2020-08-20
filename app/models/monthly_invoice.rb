class MonthlyInvoice < Invoice

  START_DATE = DateTime.now.beginning_of_month
  END_DATE = DateTime.now.end_of_month

  validates :start_date, :end_date, :status, :billable_id, :billable_type, :default_payment, presence: true
  scope :pending, -> { where(status: 'pending') }

  def self.invoice_exists?(ssl_account)
    ssl = Invoice.get_team ssl_account
    ssl && ssl.monthly_invoices
      .where(start_date: START_DATE, status: 'pending').any?
  end

  def self.get_current_invoice(ssl_account)
    ssl = Invoice.get_team ssl_account
    if ssl
      ssl.monthly_invoices.order(created_at: :desc)
        .where(start_date: START_DATE, status: 'pending').first
    else
      nil
    end
  end

  def self.last_invoice_for_month(ssl_account, exclude=nil)
    ssl = Invoice.get_team ssl_account
    ssl.monthly_invoices.order(id: :desc)
      .where(start_date: START_DATE).where.not(id: exclude).first
  end
end
