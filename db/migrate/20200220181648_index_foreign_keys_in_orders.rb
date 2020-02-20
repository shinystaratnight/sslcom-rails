class IndexForeignKeysInOrders < ActiveRecord::Migration
  def change
    add_index :orders, :ext_affiliate_id
  end
end
