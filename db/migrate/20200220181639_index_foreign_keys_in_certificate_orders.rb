class IndexForeignKeysInCertificateOrders < ActiveRecord::Migration
  def change
    add_index :certificate_orders, :acme_account_id
  end
end
