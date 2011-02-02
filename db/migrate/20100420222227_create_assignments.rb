class CreateAssignments < ActiveRecord::Migration
  def self.up
    create_table :assignments do |t|
      t.references  :user
      t.references  :role
      t.timestamps
    end
  end

  def self.down
    drop_table :assignments
  end
end
