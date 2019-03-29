class AddFingerPrintIndexToSignedCertificates < ActiveRecord::Migration
  def change
    add_index :signed_certificates, [:fingerprint]
  end
end
