class AddIsTestToCertificateOrders < ActiveRecord::Migration
  def self.up
    change_table :certificate_orders do |t|
      t.boolean :is_test
    end
  end

  def self.down
    change_table :certificate_orders do |t|
      t.remove :is_test
    end
  end
end
