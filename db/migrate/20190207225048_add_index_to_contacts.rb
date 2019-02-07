class AddIndexToContacts < ActiveRecord::Migration
  def change
    add_index :contacts,[:type, :contactable_type]
  end
end
