class CreateCaApiRequests < ActiveRecord::Migration
  def self.up
    create_table :ca_api_requests, force: true do |t|
      t.references  :api_requestable, polymorphic: true
      t.string  :request_url
			t.text    :parameters
			t.string  :method
      t.text    :response
      t.string  :type
      t.string  :ca

      t.timestamps
    end
  end

  def self.down
    drop_table :ca_api_requests
  end
end
