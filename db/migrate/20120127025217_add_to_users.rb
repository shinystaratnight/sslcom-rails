class AddToUsers < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.boolean :is_auth_token
    end

    add_index :tracked_urls, [:md5, :url], length: 100
    add_index :visitor_tokens, [:guid, :affiliate_id]
  end

  def self.down
    change_table :users do |t|
      t.remove :is_auth_token
    end

    remove_index :tracked_urls, [:md5, :url]
    remove_index :visitor_tokens, [:guid, :affiliate_id]
  end
end
