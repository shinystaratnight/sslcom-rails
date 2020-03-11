class RemoveProductOrders < ActiveRecord::Migration
  def change
    drop_table :product_orders
  end
end
