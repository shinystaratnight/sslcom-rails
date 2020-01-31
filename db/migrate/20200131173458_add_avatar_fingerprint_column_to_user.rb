class AddAvatarFingerprintColumnToUser < ActiveRecord::Migration
  def up
    add_column :users, :avatar_fingerprint, :string
  end

  def down
    remove_column :users, :avatar_fingerprint
  end
end
