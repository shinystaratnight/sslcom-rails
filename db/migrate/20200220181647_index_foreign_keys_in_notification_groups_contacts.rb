class IndexForeignKeysInNotificationGroupsContacts < ActiveRecord::Migration
  def change
    add_index :notification_groups_contacts, :contactable_id
  end
end
