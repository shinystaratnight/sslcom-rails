class AddSerialToSignedCertificates < ActiveRecord::Migration
  def change
    add_column :signed_certificates, :serial, :text, null: false
  end
end
