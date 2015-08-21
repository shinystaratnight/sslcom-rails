class AddToBillingProfile3 < ActiveRecord::Migration
  def self.up
    change_table :billing_profiles do |t|
      t.string :status
    end
  end

  def self.down
    change_table :billing_profiles do |t|
      t.remove :status
    end
  end
end
