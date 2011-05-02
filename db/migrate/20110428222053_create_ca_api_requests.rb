class CreateCaApiRequests < ActiveRecord::Migration
  def self.up
    create_table :ca_api_requests do |t|
      t.references  :api_requestable, polymorphic: true
      t.string  :request_url
			t.string  :parameters
			t.string  :method
      t.string  :response

      t.timestamps
    end
  end

  def self.down
    drop_table :ca_api_requests
  end
end
