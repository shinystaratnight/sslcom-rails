# == Schema Information
#
# Table name: notification_groups_subjects
#
#  id                    :integer          not null, primary key
#  created_page          :string(255)
#  domain_name           :string(255)
#  subjectable_type      :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  notification_group_id :integer
#  subjectable_id        :integer
#
# Indexes
#
#  index_notification_groups_subjects_on_notification_group_id  (notification_group_id)
#  index_notification_groups_subjects_on_two_fields             (subjectable_id,subjectable_type)
#

class NotificationGroupsSubject < ApplicationRecord
  belongs_to :notification_group
  belongs_to :subjectable, polymorphic: true
end
