class NotificationGroupsSubject < ApplicationRecord
  belongs_to :notification_group
  belongs_to :subjectable, polymorphic: true
end
