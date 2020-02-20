# == Schema Information
#
# Table name: sent_reminders
#
#  id                    :integer          not null, primary key
#  body                  :text(65535)
#  expires_at            :datetime
#  recipients            :string(255)
#  reminder_type         :string(255)
#  subject               :string(255)
#  trigger_value         :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  signed_certificate_id :integer
#
# Indexes
#
#  index_contacts_on_recipients_subject_trigger_value_expires_at  (recipients,subject,trigger_value,expires_at)
#  index_sent_reminders_on_signed_certificate_id                  (signed_certificate_id)
#

class SentReminder < ApplicationRecord
  serialize :trigger_value

  validates :signed_certificate_id, :uniqueness=>
    {:scope=>[:trigger_value,:expires_at]}
end
