class AddColumnsToSslAccountAndOrder < ActiveRecord::Migration
  def change
    add_column :ssl_accounts, :billing_method, :string, default: 'monthly'
    add_column :orders, :approval, :string
    add_column :certificate_contents, :approval, :string
  end
end
