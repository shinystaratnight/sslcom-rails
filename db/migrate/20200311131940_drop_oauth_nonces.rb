class DropOauthNonces < ActiveRecord::Migration
  def change
    drop_table :oauth_nonces if table_exists?(:oauth_nonces)
    drop_table :oauth_tokens if table_exists?(:oauth_tokens)
  end
end
