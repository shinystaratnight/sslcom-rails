class AddRegistrantTypeToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :registrant_type, :integer
  end
end
