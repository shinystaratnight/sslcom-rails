class CreateSentReminders < ActiveRecord::Migration
  def self.up
    create_table :sent_reminders, force: true do |t|
      t.references  :signed_certificate
      t.text        :body
      t.string      :recipients, :subject, :trigger_value
      t.datetime    :expires_at
      t.timestamps
    end
  end

  def self.down
    drop_table :sent_reminders
  end
end
