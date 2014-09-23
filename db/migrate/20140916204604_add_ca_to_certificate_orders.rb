class AddCaToCertificateOrders < ActiveRecord::Migration
  def self.up
    change_table    :certificate_orders do |t|
      t.string      :ca
    end
  end

  def self.down
    change_table    :certificate_orders do |t|
      t.remove      :ca
    end
  end
end
