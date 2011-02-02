class CreateValidations < ActiveRecord::Migration
  def self.up
    create_table :validations do |t|
      t.string :label
      t.string :notes
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
      t.string :workflow_state
      t.string :domain
      t.timestamps
    end
  end

  def self.down
    drop_table :validations
  end
end
