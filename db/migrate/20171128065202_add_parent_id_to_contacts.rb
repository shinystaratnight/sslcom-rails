class AddParentIdToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :parent_id, :integer
    add_index :contacts, [:id, :parent_id]
  end
end
