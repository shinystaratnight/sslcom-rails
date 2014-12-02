class AddToCaApiRequests < ActiveRecord::Migration
  def self.up
    change_table :ca_api_requests do |t|
      t.text :raw_request
      t.text :request_method
    end
  end

  def self.down
    change_table :ca_api_requests do |t|
      t.remove :raw_request, :request_method
    end
  end
end
