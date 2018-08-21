class AddNotifyAllToNotificationGroup < ActiveRecord::Migration
  def self.up
    change_table :notification_groups do |t|
      t.boolean  :notify_all, :default => true
    end
  end

  def self.down
    change_table  :notification_groups do |t|
      t.remove  :notify_all
    end
  end
end
