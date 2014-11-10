class AddToBillingProfile < ActiveRecord::Migration
  def self.up
    change_table :billing_profiles do |t|
      t.string :encrypted_card_number
      t.string :encrypted_card_number_salt
      t.string :encrypted_card_number_iv    end
  end

  def self.down
    change_table :billing_profiles do |t|
      t.remove :encrypted_card_number, :encrypted_card_number_salt, :encrypted_card_number_iv
    end
  end
end
