class AddUrlSlugToSslAccounts < ActiveRecord::Migration
  def change
    add_column :ssl_accounts, :ssl_slug, :string
    add_column :ssl_accounts, :company_name, :string
  end
end
