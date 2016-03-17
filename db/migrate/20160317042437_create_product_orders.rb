class CreateProductOrders < ActiveRecord::Migration
  def self.up
    create_table :product_orders, force: true do |t|
      t.references  :ssl_account
      t.string      :workflow_state
      t.string      :ref
      t.string      :rebill
      t.string      :value
      t.integer     :amount
      t.body        :notes
      t.timestamps
    end

    create_table :product_orders_sub_product_orders, force: true do |t|
      t.references  :product_order
      t.integer     :sub_product_order_id
      t.timestamps
    end
  end

  def self.down
    drop_table  :product_orders, :product_orders_sub_product_orders
  end
end
