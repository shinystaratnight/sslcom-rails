class CreateBillingProfiles < ActiveRecord::Migration
  def self.up
    create_table :billing_profiles, force: true do |t|
      t.references :ssl_account
      t.string  :description
      t.string  :first_name
      t.string  :last_name
      t.string  :address_1
      t.string  :address_2
      t.string  :country
      t.string  :city
      t.string  :state
      t.string  :postal_code
      t.string  :phone
      t.string  :company
      t.string  :credit_card
      t.string  :card_number
      t.integer :expiration_month
      t.integer :expiration_year
      t.string  :security_code
      t.string  :last_digits
      t.binary  :data
      t.binary  :salt
      t.string  :notes

      t.timestamps
    end
  end

  def self.down
    drop_table :billing_profiles
  end
end
