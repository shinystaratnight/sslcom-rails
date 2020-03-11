class RemoveProductOrders < ActiveRecord::Migration
  def change
    drop_table :product_orders if table_exists?(:product_orders)
  end
end
