class AddIndexesToTables < ActiveRecord::Migration
  def change
    add_index :certificate_orders, [:id, :ref, :ssl_account_id]
    add_index :line_items, [:order_id, :sellable_id, :sellable_type]
    add_index :orders, [:id, :state]
    add_index :ssl_accounts, [:id, :created_at]
  end
end
