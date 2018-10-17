class AddFieldsToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :status, :integer
    add_column :contacts, :user_id, :integer
    add_index :contacts, :user_id
  end
end
