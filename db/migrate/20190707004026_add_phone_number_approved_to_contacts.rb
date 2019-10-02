class AddPhoneNumberApprovedToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :phone_number_approved, :boolean, :default => false
  end
end
