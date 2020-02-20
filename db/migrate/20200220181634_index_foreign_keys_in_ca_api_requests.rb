class IndexForeignKeysInCaApiRequests < ActiveRecord::Migration
  def change
    add_index :ca_api_requests, :approval_id
  end
end
