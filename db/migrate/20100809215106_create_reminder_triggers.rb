class CreateReminderTriggers < ActiveRecord::Migration
  def self.up
    create_table :reminder_triggers, force: true do |t|
      t.integer :name
      t.timestamps
    end
  end

  def self.down
    drop_table :reminder_triggers
  end
end
