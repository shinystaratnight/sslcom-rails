class IndexForeignKeysInPermissions < ActiveRecord::Migration
  def change
    add_index :permissions, :subject_id
  end
end
