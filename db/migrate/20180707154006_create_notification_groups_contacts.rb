class CreateNotificationGroupsContacts < ActiveRecord::Migration
  # def change
  #   create_table :notification_groups_contacts do |t|
  #   end
  # end

  def self.up
    create_table :notification_groups_contacts, force: true do |t|
      t.string      :email_address              # user if contactable is blank
      t.integer     :notification_group_id
      t.integer     :contactable_id             # can be contact
      t.string      :contactable_type           # 'Contact'
      t.timestamps
    end

    add_index :notification_groups_contacts, :notification_group_id
  end

  def self.down
    drop_table :notification_groups_contacts
  end
end
