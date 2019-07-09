class ChangeCaApiRequestsColumn < ActiveRecord::Migration
  def change
    change_column :ca_api_requests, :response, :text, :limit => 16777215
  end
end
