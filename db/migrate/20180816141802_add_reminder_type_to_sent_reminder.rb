class AddReminderTypeToSentReminder < ActiveRecord::Migration
  def self.up
    change_table  :sent_reminders do |t|
      t.string  :reminder_type
    end
  end

  def self.down
    change_table  :sent_reminders do |t|
      t.remove  :reminder_type
    end
  end
end
