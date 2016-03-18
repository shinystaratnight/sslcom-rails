class CreateProductOrders < ActiveRecord::Migration
  def self.up
    create_table :product_orders, force: true do |t|
      t.references  :ssl_account
      t.references  :product
      t.string      :workflow_state
      t.string      :ref
      t.string      :rebill # what period ie nil, daily, weekly, quarterly, etc
      t.string      :value # arbitrary
      t.integer     :amount
      t.text        :notes
      t.timestamps
    end

    create_table :product_orders_sub_product_orders, force: true do |t|
      t.references  :product_order
      t.integer     :sub_product_order_id
      t.timestamps
    end

    change_table :line_items do |t|
      t.integer     :qty
    end
  end

  def self.down
    drop_table    :product_orders
    drop_table    :product_orders_sub_product_orders

    change_table :line_items do |t|
      t.remove        :qty
    end
  end
end
