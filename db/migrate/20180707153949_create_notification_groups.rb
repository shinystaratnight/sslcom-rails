class CreateNotificationGroups < ActiveRecord::Migration
  # def change
  #   create_table :notification_groups do |t|
  #   end
  # end

  def self.up
    create_table :notification_groups, force: true do |t|
      t.references  :ssl_account
      t.string      :ref, :null => false
      t.string      :friendly_name, :null => false
      t.timestamps
    end

    add_index :notification_groups, :ssl_account_id
    add_index :notification_groups, [:ssl_account_id, :ref]
  end

  def self.down
    drop_table :notification_groups
  end
end
