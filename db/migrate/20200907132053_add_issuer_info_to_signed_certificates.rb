class AddIssuerInfoToSignedCertificates < ActiveRecord::Migration
  def change
    add_column :signed_certificates, :issuer_source, :string
    add_column :signed_certificates, :issuer_identifier, :string
  end
end
