class CreateApiCredentials < ActiveRecord::Migration
  def self.up
    create_table    :api_credentials, force: true do |t|
      t.references  :ssl_account
      t.string      :account_key, :secret_key
      t.timestamps
    end
  end

  def self.down
    drop_table  :api_credentials
  end
end
