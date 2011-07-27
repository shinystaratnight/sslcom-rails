class CreateAffiliates < ActiveRecord::Migration
  def self.up
    create_table :affiliates, force: true do |t|
      t.references :ssl_account
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone

      t.string :organization
      t.string :address1
      t.string :address2
      t.string :postal_code
      t.string :city
      t.string :state
      t.string :country
      t.string :website
      t.string :contact_email
      t.string :contact_phone

      t.string :tax_number
      t.string :payout_method
      t.string :payout_threshold
      t.string :payout_frequency
      t.string :bank_name
      t.string :bank_routing_number
      t.string :bank_account_number
      t.string :swift_code
      t.string :checks_payable_to
      t.string :epassporte_account
      t.string :paypal_account
      t.string :type_organization

      t.timestamps
    end
  end

  def self.down
    drop_table :affiliates
  end
end
