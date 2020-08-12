class ModifyWeakKeys < ActiveRecord::Migration
  def change
    rename_table :weak_keys, :reject_keys
    rename_column :reject_keys, :sha1_hash, :fingerprint 
    add_column :reject_keys, :source, :string
    add_column :reject_keys, :type, :string
  end
end
