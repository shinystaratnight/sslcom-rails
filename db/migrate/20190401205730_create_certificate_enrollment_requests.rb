class CreateCertificateEnrollmentRequests < ActiveRecord::Migration
  def change
    create_table :certificate_enrollment_requests do |t|
      t.references :certificate, index: true, null: false
      t.references :ssl_account, index: true, null: false
      t.references :user, index: true
      t.references :order, index: true
      t.integer :duration, null: false
      t.text :domains, null: false
      t.text :common_name
      t.text :signing_request
      t.integer :server_software_id
      t.integer :status
      t.timestamps null: false
    end
  end
end
