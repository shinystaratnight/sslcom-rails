class IndexForeignKeysInAutoRenewals < ActiveRecord::Migration
  def change
    add_index :auto_renewals, :certificate_order_id
    add_index :auto_renewals, :order_id
  end
end
