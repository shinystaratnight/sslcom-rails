class AddParentIdToCertificateOrders < ActiveRecord::Migration
  def self.up
    change_table :certificate_orders do |t|
      t.integer :renewal_id
    end
  end

  def self.down
    change_table :certificate_orders do |t|
      t.remove :renewal_id
    end
  end
end
