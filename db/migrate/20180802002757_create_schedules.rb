class CreateSchedules < ActiveRecord::Migration
  # def change
  #   create_table :schedules do |t|
  #   end
  # end

  def self.up
    create_table :schedules, force: true do |t|
      t.references  :notification_group
      t.string      :schedule_type, :null => false
      t.string      :schedule_value, :null => false
      t.timestamps
    end

    add_index :schedules, :notification_group_id
  end

  def self.down
    drop_table :schedules
  end
end
