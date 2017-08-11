class UpdateColumnsForCaApiRequests < ActiveRecord::Migration
  def change
    change_column :ca_api_requests, :request_url, :text
  end
end
