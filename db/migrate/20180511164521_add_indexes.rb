class AddIndexes < ActiveRecord::Migration
  def change
    add_index :signed_certificates, :ca_id
    add_index :signed_certificates, :strength
    add_index :ssl_accounts, [:acct_number,:company_name,:ssl_slug]
    add_index :csrs, [:sig_alg,:common_name,:email]
  end
end
