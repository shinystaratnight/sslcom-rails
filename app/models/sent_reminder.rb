class SentReminder < ActiveRecord::Base
  serialize :trigger_value

  validates :signed_certificate_id, :uniqueness=>
    {:scope=>[:trigger_value,:expires_at]}
end
