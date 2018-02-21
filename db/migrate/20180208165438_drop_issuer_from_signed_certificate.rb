class DropIssuerFromSignedCertificate < ActiveRecord::Migration
  def change
    remove_column :signed_certificates, :issuer, :string
    add_reference  :signed_certificates, :ca, foreign_key: true

  end
end
