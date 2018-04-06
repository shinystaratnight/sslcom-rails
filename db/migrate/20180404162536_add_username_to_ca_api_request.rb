class AddUsernameToCaApiRequest < ActiveRecord::Migration
  def change
    add_column :ca_api_requests, :username, :string
    add_column :ca_api_requests, :approval_id, :string
    add_column :ca_api_requests, :certificate_chain, :text

    add_index :ca_api_requests,[:username, :approval_id], :unique => true
  end
end
