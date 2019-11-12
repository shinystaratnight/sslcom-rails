class AddHmacToApiCredentials < ActiveRecord::Migration
  def change
    add_column :api_credentials, :hmac, :string
  end
end
