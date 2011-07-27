class CreateApis < ActiveRecord::Migration
  def self.up
    create_table :apis, force: true do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :apis
  end
end
