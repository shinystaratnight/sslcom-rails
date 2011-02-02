class CreateSignedCertificates < ActiveRecord::Migration
  def self.up
    create_table :signed_certificates do |t|
      t.references    :csr
      t.integer       :parent_id
      t.string        :common_name
      t.string        :organization
      t.text          :organization_unit
      t.string        :address1
      t.string        :address2
      t.string        :locality
      t.string        :state
      t.string        :postal_code
      t.string        :country
      t.datetime      :effective_date, :expiration_date
      t.string        :fingerprintSHA
      t.string        :fingerprint
      t.text          :signature
      t.string        :url
      t.text          :body
      t.boolean       :parent_cert
      t.timestamps
    end
  end

  def self.down
    drop_table :signed_certificates
  end
end

