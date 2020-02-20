class IndexForeignKeysInCdns < ActiveRecord::Migration
  def change
    add_index :cdns, :resource_id
  end
end
