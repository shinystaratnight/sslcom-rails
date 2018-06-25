class CreateCertificateCaMappings < ActiveRecord::Migration
  def change
    create_table :cas_certificates do |t|
      t.references  :certificate, null: false, index: true, limit: 4
      t.references  :ca, null: false, index: true, limit: 4
      t.string      :status
      t.timestamps
    end

    add_index :cas_certificates, [:certificate_id, :ca_id]

    add_column :cas, :caa_issuers, :string
    add_column :cas, :host, :string
    add_column :cas, :admin_host, :string
  end
end
