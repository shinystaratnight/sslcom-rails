class CreateTrackedUrls < ActiveRecord::Migration
  def self.up
    create_table :tracked_urls, force: true do |t|
      t.text        :url
      t.string      :md5
      t.timestamps
    end
  end

  def self.down
    drop_table  :tracked_urls
  end
end
