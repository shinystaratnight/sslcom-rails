class AddUniqueValueToCsrs < ActiveRecord::Migration
  def change
    add_column :csrs, :unique_value, :string
    add_column :csrs, :public_key_sha1, :string
    add_column :csrs, :public_key_sha256, :string
    add_column :csrs, :public_key_md5, :string

    add_index :csrs, [:public_key_sha1, :unique_value], unique: true
  end
end
