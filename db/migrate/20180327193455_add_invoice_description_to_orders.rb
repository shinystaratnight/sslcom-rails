class AddInvoiceDescriptionToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :invoice_description, :string
  end
end
