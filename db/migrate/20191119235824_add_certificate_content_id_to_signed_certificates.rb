class AddCertificateContentIdToSignedCertificates < ActiveRecord::Migration
  def change
    add_column :signed_certificates, :certificate_content_id, :integer
  end
end
