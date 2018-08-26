class CreateCasCertficatesSslAccounts < ActiveRecord::Migration
  def change
    create_table :cas_certificates_ssl_accounts do |t|
      t.references  :cas_certificate, null: false, index: true, limit: 4
      t.references  :ssl_account, null: false, index: true, limit: 4
      t.string      :status
      t.timestamps
    end
    add_index :cas_certificates_ssl_accounts, [:cas_certificate_id, :ssl_account_id],
              name: "index_cas_certficates_ssl_accounts"

    remove_column :cas_certificates, :ssl_account_id, :integer
  end
end


