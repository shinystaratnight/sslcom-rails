class CreateDiscountJoinTables < ActiveRecord::Migration
  def self.up
    create_table :discounts_orders, force: true do |t|
      t.references :discount
      t.references :order
      t.timestamps
    end
    create_table :discounts_certificates, force: true do |t|
      t.references :discount
      t.references :certificate
      t.timestamps
    end
  end

  def self.down
    drop_table :discounts_orders
    drop_table :discounts_certificates
  end
end
