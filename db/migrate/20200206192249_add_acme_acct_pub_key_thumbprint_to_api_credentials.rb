class AddAcmeAcctPubKeyThumbprintToApiCredentials < ActiveRecord::Migration
  def change
    add_column :api_credentials, :acme_acct_pub_key_thumbprint, :string, index: true
  end
end
