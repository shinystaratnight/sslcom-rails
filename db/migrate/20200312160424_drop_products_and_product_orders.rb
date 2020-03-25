class DropProductsAndProductOrders < ActiveRecord::Migration
  def change
    drop_table :products if table_exists?(:products)
    drop_table :product_orders if table_exists?(:product_orders)
    drop_table :product_orders_sub_product_orders if table_exists?(:product_orders_sub_product_orders)
    drop_table :products_sub_products if table_exists?(:products_sub_products)
  end
end
