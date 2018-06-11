class AddSecTypeToSslAccounts < ActiveRecord::Migration
  def change
    add_column :ssl_accounts, :sec_type, :string
  end
end
