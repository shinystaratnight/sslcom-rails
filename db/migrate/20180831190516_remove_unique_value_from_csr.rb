class RemoveUniqueValueFromCsr < ActiveRecord::Migration
  def change
    remove_index :csrs, [:public_key_sha1, :unique_value]
    remove_column :csrs, :unique_value, :string
  end
end
