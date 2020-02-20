class IndexForeignKeysInDiscountsCertificates < ActiveRecord::Migration
  def change
    add_index :discounts_certificates, :certificate_id
    add_index :discounts_certificates, :discount_id
  end
end
