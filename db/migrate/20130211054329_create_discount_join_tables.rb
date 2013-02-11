class CreateDiscountJoinTables < ActiveRecord::Migration
  def self.up
    create_table :discounts_orders, force: true do |t|
      t.references :discount
      t.references :order
      t.string     :status
      t.string     :notes
      t.timestamps
    end
  end

  def self.down
    drop_table :discounts_orders
  end
end
