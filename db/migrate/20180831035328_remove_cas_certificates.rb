class RemoveCasCertificates < ActiveRecord::Migration
  def change
    remove_index :cas_certificates_ssl_accounts, name: "index_cas_certficates_ssl_accounts"
    drop_table :cas_certificates_ssl_accounts

    add_column :cas_certificates, :ssl_account_id, :integer
  end
end
