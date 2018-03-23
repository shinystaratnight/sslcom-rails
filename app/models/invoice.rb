class Invoice < ActiveRecord::Base
  include Filterable
  include Sortable
  
  attr_accessor :credit_reason
  
  validates :first_name, :last_name, :address_1, :country, :city,
    :state, :postal_code, presence: true, unless: Proc.new {|i| i.type == 'MonthlyInvoice'}
  
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
    
    if p[:team].present?
      found = SslAccount.where("ssl_slug = ? OR acct_number = ? OR id = ?", p[:team], p[:team], p[:team])
      filters[:billable_id] = { '=' => found.first.id } if found.any?
    end
    result = filter(filters)
    result = result.where("orders.reference_number" => p[:order_ref]) if p[:order_ref].present?
    result
  end
end