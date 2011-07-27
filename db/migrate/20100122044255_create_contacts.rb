class CreateContacts < ActiveRecord::Migration
  def self.up
    create_table :contacts, force: true do |t|
      t.string :title, :first_name, :last_name, :company_name, :department, 
        :po_box, :address1, :address2, :address3, :city, :state, :country,
        :postal_code, :email, :phone, :ext, :fax, :notes, :type
      t.string    :roles, :default => "--- []"
      t.references :contactable, :polymorphic => true
      t.timestamps
    end
  end

  def self.down
    drop_table  :contacts
  end
end
