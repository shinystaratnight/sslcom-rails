class AddToSslAccounts < ActiveRecord::Migration
  def change
    add_column :ssl_accounts, :duo_enabled, :boolean
    add_column :ssl_accounts, :duo_own_used, :boolean
  end
end
