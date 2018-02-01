class AddIssuerToSignedCertificates < ActiveRecord::Migration
  def change
    add_column :signed_certificates, :issuer, :string
  end
end
