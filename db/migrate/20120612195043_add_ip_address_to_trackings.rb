class AddIpAddressToTrackings < ActiveRecord::Migration
  def self.up
    change_table :trackings do |t|
      t.string :remote_ip
    end
  end

  def self.down
    change_table :trackings do |t|
      t.remove :remote_ip
    end
  end
end
