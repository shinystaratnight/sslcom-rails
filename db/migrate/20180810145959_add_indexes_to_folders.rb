class AddIndexesToFolders < ActiveRecord::Migration
  def change
    add_index :folders, [:default, :archived, :name, :ssl_account_id, :expired, :active, :revoked],
              name: "index_folder_statuses"
    add_index :folders, [:default, :name, :ssl_account_id]
    add_index :folders, [:archived, :name, :ssl_account_id]
    add_index :folders, [:name, :ssl_account_id, :expired]
    add_index :folders, [:name, :ssl_account_id, :active, :revoked]
    add_index :folders, [:name, :ssl_account_id, :revoked]
  end
end
