class AddScanPortToNotificationGroup < ActiveRecord::Migration
  def self.up
    change_table :notification_groups do |t|
      t.string  :scan_port, :default => '443'
    end
  end

  def self.down
    change_table  :notification_groups do |t|
      t.remove  :scan_port
    end
  end
end
