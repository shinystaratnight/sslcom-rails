class ChangeHmacToHmacKeyOnApiCredentials < ActiveRecord::Migration
  def change
    rename_column :api_credentials, :hmac, :hmac_key
  end
end
