class AddSslAccountIdToCasCertificates < ActiveRecord::Migration
  def change
    add_column :cas_certificates, :ssl_account_id, :integer
    add_index :cas_certificates, :ssl_account_id

    remove_column :cas, :profile_type
    remove_column :certificates, :ca_certificate_id
  end
end
