class RemoveSignedCertificateIdFromSentReminders < ActiveRecord::Migration
  def change
    remove_column :sent_reminders, :signed_certificate_id, :integer
  end
end
