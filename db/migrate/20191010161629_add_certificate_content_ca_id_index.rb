class AddCertificateContentCaIdIndex < ActiveRecord::Migration
  def change
    add_index :certificate_contents, [:ca_id]
  end
end
