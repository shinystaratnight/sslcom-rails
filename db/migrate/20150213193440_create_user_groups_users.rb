class CreateUserGroupsUsers < ActiveRecord::Migration
  def self.up
    create_table :user_groups_users, force: true do |t|
      t.references :user
      t.references :user_group
      t.string     :status
      t.string     :notes
      t.timestamps
    end
  end

  def self.down
    drop_table :user_groups_users
  end
end
