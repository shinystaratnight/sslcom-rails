class AddFieldsToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :type, :string
    add_column :invoices, :billable_id, :integer
    add_column :invoices, :billable_type, :string
    add_column :invoices, :start_date, :datetime
    add_column :invoices, :end_date, :datetime
    add_column :invoices, :reference_number, :string
    add_column :invoices, :status, :string
    add_column :orders,   :invoice_id, :integer
  end
end
