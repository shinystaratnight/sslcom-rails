class AddSavedDefaultToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :saved_default, :boolean, default: false
  end
end
