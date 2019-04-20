class AddFingerPrintIndexToSignedCertificates < ActiveRecord::Migration
  def change
    add_index :signed_certificates, [:fingerprint]
    add_index :signed_certificates, [:ejbca_username]
  end
end
