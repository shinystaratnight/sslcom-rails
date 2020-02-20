class IndexForeignKeysInSslAccounts < ActiveRecord::Migration
  def change
    add_index :ssl_accounts, :default_folder_id
  end
end
