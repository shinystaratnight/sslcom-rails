class AddSslAccountIdToCasCertificates < ActiveRecord::Migration
  def change
    add_column :cas_certificates, :ssl_account_id, :integer
    add_index :cas_certificates, :ssl_account_id

    add_column :cas, :type, :string, required: true

    remove_column :cas, :profile_type, :string
    remove_column :certificates, :ca_certificate_id, :integer

    remove_foreign_key :signed_certificates, :ca_id
    remove_column :signed_certificates, :ca_id, :integer
  end
end
