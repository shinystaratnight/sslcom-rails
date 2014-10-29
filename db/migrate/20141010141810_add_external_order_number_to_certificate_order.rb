class AddExternalOrderNumberToCertificateOrder < ActiveRecord::Migration
  def self.up
    change_table :certificate_orders do |t|
      t.string :external_order_number
    end
  end

  def self.down
    change_table :certificate_orders do |t|
      t.remove :external_order_number
    end
  end
end
