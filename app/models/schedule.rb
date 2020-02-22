# == Schema Information
#
# Table name: schedules
#
#  id                    :integer          not null, primary key
#  schedule_type         :string(255)      not null
#  schedule_value        :string(255)      default("2"), not null
#  created_at            :datetime
#  updated_at            :datetime
#  notification_group_id :integer
#
# Indexes
#
#  index_schedules_on_notification_group_id  (notification_group_id)
#

class Schedule < ApplicationRecord
  belongs_to :notification_group
end
