class IndexForeignKeysInGroupings < ActiveRecord::Migration
  def change
    add_index :groupings, :parent_id
    add_index :groupings, :ssl_account_id
  end
end
