class AddApprovedToSslAccountUsers < ActiveRecord::Migration
  def change
    add_column :ssl_account_users, :approved, :boolean, default: false
    add_column :ssl_account_users, :approval_token, :string
    add_column :ssl_account_users, :token_expires, :datetime
  end
end
