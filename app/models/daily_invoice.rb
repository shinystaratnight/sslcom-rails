class DailyInvoice < Invoice
  
  START_DATE = DateTime.now.beginning_of_day
  END_DATE = DateTime.now.end_of_day
  
  def self.invoice_exists?(ssl_account_id)
    ssl = SslAccount.find ssl_account_id
    ssl && ssl.daily_invoices
      .where(start_date: START_DATE, status: 'pending').any?
  end
  
  def self.get_current_invoice(ssl_account_id)
    ssl = SslAccount.find ssl_account_id
    if ssl
      ssl.daily_invoices.order(created_at: :desc)
        .where(start_date: START_DATE, status: 'pending').first
    else
      nil
    end
  end
  
  def self.last_invoice_for_day(ssl_account_id, exclude=nil)
    ssl = SslAccount.find ssl_account_id
    ssl.daily_invoices.order(id: :desc)
      .where(start_date: START_DATE).where.not(id: exclude).first
  end
end
