class AddIssuerToSignedCertificates < ActiveRecord::Migration
  def change
    add_column :signed_certificates, :issuer, :string # primarily used for shadowing
    add_index :signed_certificates, [:issuer]
  end
end
