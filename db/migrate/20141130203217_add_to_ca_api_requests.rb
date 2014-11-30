class AddToCaApiRequests < ActiveRecord::Migration
  def self.up
    change_table :ca_api_requests do |t|
      t.text :raw_request
    end
  end

  def self.down
    change_table :ca_api_requests do |t|
      t.remove :raw_request
    end
  end
end
