class CreateUserGroups < ActiveRecord::Migration
  def up
    create_table :user_groups, force: true do |t|
      t.references  :ssl_account
      t.string      :roles, :default => "--- []"
      t.string      :name
      t.text        :description
      t.text        :notes
    end
  end

  def down
    drop_table :user_groups
  end
end
