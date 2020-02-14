# == Schema Information
#
# Table name: notification_groups_contacts
#
#  id                    :integer          not null, primary key
#  contactable_type      :string(255)
#  email_address         :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  contactable_id        :integer
#  notification_group_id :integer
#
# Indexes
#
#  index_notification_groups_contacts_on_notification_group_id  (notification_group_id)
#

class NotificationGroupsContact < ApplicationRecord
  belongs_to :notification_group
  belongs_to :contactable, polymorphic: true
end
