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
#  index_notification_groups_contacts_on_contactable_id         (contactable_id)
#  index_notification_groups_contacts_on_notification_group_id  (notification_group_id)
#

FactoryBot.define do
  factory :notification_groups_contact do
    sequence(:email_address) { |n| "test_user#{n}@gmail.com" }
  end
end
