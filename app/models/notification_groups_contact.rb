class NotificationGroupsContact < ActiveRecord::Base
  belongs_to :notification_group
  belongs_to :contactable, polymorphic: true
end