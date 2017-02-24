class AddInvitedDeclinedToSslAccountUsers < ActiveRecord::Migration
  def change
    add_column :ssl_account_users, :invited_at, :datetime
    add_column :ssl_account_users, :declined_at, :datetime

    add_column :users, :persist_notice, :boolean, default: false
  end
end
