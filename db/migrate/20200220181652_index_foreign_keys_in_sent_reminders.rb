class IndexForeignKeysInSentReminders < ActiveRecord::Migration
  def change
    add_index :sent_reminders, :signed_certificate_id
  end
end
