class AddIndexToCaApiRequests < ActiveRecord::Migration
  def change
    add_index :ca_api_requests, [:type,:username]
  end
end
