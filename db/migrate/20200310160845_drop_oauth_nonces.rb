class DropOauthNonces < ActiveRecord::Migration
  def change
    drop_table :oauth_nonces
  end
end
