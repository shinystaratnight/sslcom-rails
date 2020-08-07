class NotificationGroupsContact < ApplicationRecord
  belongs_to :notification_group
  belongs_to :contactable, polymorphic: true
end
