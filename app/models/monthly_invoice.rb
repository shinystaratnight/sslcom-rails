# == Schema Information
#
# Table name: invoices
#
#  id               :integer          not null, primary key
#  address_1        :string(255)
#  address_2        :string(255)
#  billable_type    :string(255)
#  city             :string(255)
#  company          :string(255)
#  country          :string(255)
#  default_payment  :string(255)
#  description      :text(65535)
#  end_date         :datetime
#  fax              :string(255)
#  first_name       :string(255)
#  last_name        :string(255)
#  notes            :text(65535)
#  phone            :string(255)
#  postal_code      :string(255)
#  reference_number :string(255)
#  start_date       :datetime
#  state            :string(255)
#  status           :string(255)
#  tax              :string(255)
#  type             :string(255)
#  vat              :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  billable_id      :integer
#  order_id         :integer
#
# Indexes
#
#  index_invoices_on_billable_id_and_billable_type  (billable_id,billable_type)
#  index_invoices_on_id_and_type                    (id,type)
#  index_invoices_on_order_id                       (order_id)
#

class MonthlyInvoice < Invoice
  
  START_DATE = DateTime.now.beginning_of_month
  END_DATE = DateTime.now.end_of_month
  
  validates :start_date, :end_date, :status, :billable_id, :billable_type, :default_payment, presence: true
  
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
