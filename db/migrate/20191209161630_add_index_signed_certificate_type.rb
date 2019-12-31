class AddIndexSignedCertificateType < ActiveRecord::Migration
  def change
    add_index :signed_certificates, [:type, :certificate_content_id],
              name: "index_signed_certificates_t_cci"
  end
end
