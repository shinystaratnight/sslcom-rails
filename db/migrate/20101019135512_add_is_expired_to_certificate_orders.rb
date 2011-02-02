class AddIsExpiredToCertificateOrders < ActiveRecord::Migration
  def self.up
    change_table :certificate_orders do |t|
      t.boolean :is_expired
    end
    add_index :certificate_orders, :is_expired
  end

  def self.down
    change_table :certificate_orders do |t|
      t.remove :is_expired
    end
    remove_index :certificate_orders, :is_expired
  end
end
