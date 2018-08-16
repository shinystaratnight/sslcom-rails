class AddTypeToSignedCertificate < ActiveRecord::Migration
  def change
    add_column :signed_certificates, :type, :string # IoT, shadow, non x509, etc
  end
end
