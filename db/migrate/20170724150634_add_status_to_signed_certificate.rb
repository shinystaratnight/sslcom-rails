class AddStatusToSignedCertificate < ActiveRecord::Migration
  def change
    add_column :signed_certificates, :status, :text, null: false #uniquely identifies signed certificates
  end
end
