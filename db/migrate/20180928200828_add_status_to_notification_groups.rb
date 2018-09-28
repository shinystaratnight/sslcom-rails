class AddStatusToNotificationGroups < ActiveRecord::Migration
  def change
    add_column  :notification_groups, :status, :boolean
  end
end
