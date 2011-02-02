  class CreateTrackings < ActiveRecord::Migration
    def self.up
      create_table  :trackings do |t|
        t.references :tracked_url
        t.references :visitor_token
        t.integer    :referer_id
        t.timestamps
      end
    end

    def self.down
      drop_table    :trackings
    end
  end
