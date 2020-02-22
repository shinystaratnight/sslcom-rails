class IndexForeignKeysInCertificateApiRequests < ActiveRecord::Migration
  def change
    add_index :certificate_api_requests, :ca_certificate_id
    add_index :certificate_api_requests, :country_id
    add_index :certificate_api_requests, :server_software_id
  end
end
