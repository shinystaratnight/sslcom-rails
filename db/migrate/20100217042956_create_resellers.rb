class CreateResellers < ActiveRecord::Migration
  def self.up
    create_table :resellers do |t|
      t.references  :ssl_account
      t.references  :reseller_tier
      t.string  :first_name
      t.string  :last_name
      t.string  :email
      t.string  :phone
      t.string  :organization
      t.string  :address1
      t.string  :address2
      t.string  :address3
      t.string  :po_box
      t.string  :postal_code
      t.string  :city
      t.string  :state
      t.string  :country
      t.string  :phone
      t.string  :ext
      t.string  :fax
      t.string  :website
      t.string  :tax_number
      t.string  :roles
      t.string  :type_organization
      t.string  :workflow_state
      t.timestamps
    end
  end

  def self.down
    drop_table :resellers
  end
end
