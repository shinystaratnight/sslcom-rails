class AddCsrIdAndTypeIndexToSignedCertificates < ActiveRecord::Migration
  def change
    add_index :signed_certificates, [:csr_id, :type]
  end
end
