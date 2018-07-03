class AddSslAccountIdToCasCertificates < ActiveRecord::Migration
  def change
    add_column :cas_certificates, :ssl_account_id, :integer
    add_column :cas, :type, :string, required: true
    add_index :cas_certificates, :ssl_account_id

    remove_column :cas, :profile_type, :string
    change_column :cas, :end_entity, :string
  end
end
