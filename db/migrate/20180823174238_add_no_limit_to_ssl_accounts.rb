class AddNoLimitToSslAccounts < ActiveRecord::Migration
  def change
    add_column :ssl_accounts, :no_limit, :boolean, default: false
  end
end
