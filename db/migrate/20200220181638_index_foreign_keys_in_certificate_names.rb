class IndexForeignKeysInCertificateNames < ActiveRecord::Migration
  def change
    add_index :certificate_names, :acme_account_id
  end
end
