class DropOauthTokens < ActiveRecord::Migration
  def change
    drop_table :oauth_tokens
  end
end
