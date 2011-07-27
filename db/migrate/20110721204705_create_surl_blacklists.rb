class CreateSurlBlacklists < ActiveRecord::Migration
  def self.up
    create_table :surl_blacklists, force: true do |t|
      t.string     :fingerprint
      t.timestamps
    end
  end

  def self.down
    drop_table :surl_blacklists
  end
end
