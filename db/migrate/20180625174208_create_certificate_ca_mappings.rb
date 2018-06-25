class CreateCertificateCaMappings < ActiveRecord::Migration
  def change
    create_table :certificate_cas do |t|
      t.references  :certificate, null: false, index: true, limit: 4
      t.references  :ca, null: false, index: true, limit: 4
      t.string      :status
      t.timestamps
    end

    add_index :certificate_cas, [:certificate_id, :ca_id]

    add_column :cas, :caa_issuers, :string
    add_column :cas, :url, :string
    add_column :cas, :ev_rsa_profile, :string
    add_column :cas, :ev_ecc_profile, :string
    add_column :cas, :rsa_profile, :string
    add_column :cas, :ecc_profile, :string
    add_column :cas, :end_entity_profile, :string
  end
end
