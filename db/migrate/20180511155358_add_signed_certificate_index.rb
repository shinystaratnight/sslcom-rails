class AddSignedCertificateIndex < ActiveRecord::Migration
  def change
    add_index :signed_certificates, :common_name
  end
end
