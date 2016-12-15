class AddUserEnabledToSslAccountUsers < ActiveRecord::Migration
  def change
    add_column :ssl_account_users, :user_enabled, :boolean, default: true
  end
end
