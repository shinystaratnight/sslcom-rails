class CreateGroupings < ActiveRecord::Migration
  def self.up
    create_table :groupings, force: true do |t|
      t.references  :ssl_account
      t.string      :type, :name, :nav_tool
      t.integer     :parent_id

      t.timestamps
    end
  end

  def self.down
    drop_table :groupings
  end
end
