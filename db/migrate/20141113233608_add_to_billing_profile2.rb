class AddToBillingProfile2 < ActiveRecord::Migration
  def self.up
    change_table :billing_profiles do |t|
      t.string :vat, :tax
    end
  end

  def self.down
    change_table :billing_profiles do |t|
      t.remove :vat, :tax
    end
  end
end
