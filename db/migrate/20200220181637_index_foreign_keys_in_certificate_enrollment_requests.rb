class IndexForeignKeysInCertificateEnrollmentRequests < ActiveRecord::Migration
  def change
    add_index :certificate_enrollment_requests, :server_software_id
  end
end
