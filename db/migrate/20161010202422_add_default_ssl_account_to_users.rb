class AddDefaultSslAccountToUsers < ActiveRecord::Migration
  def change
    add_column :users, :default_ssl_account, :integer
  end
end
