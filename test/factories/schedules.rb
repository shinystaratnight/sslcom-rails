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

FactoryBot.define do
  factory :schedule do
    schedule_type { 'Simple' }

    trait :hourly do
      schedule_value { '1' }
    end

    trait :daily do
      schedule_value { '2' }
    end
    
    trait :weekly do
      schedule_value { '3' }
    end

    trait :monthly do
      schedule_value { '4' }
    end

    trait :yearly do
      schedule_value { '5' }
    end
  end
end
