class AddToCdns < ActiveRecord::Migration
  def self.up
    change_table :cdns do |t|
      t.string :custom_domain_name
      t.string :certificate_order_ref
    end
  end

  def self.down
    change_table :cdns do |t|
      t.remove :custom_domain_name
      t.remove :certificate_order_ref
    end
  end
end
