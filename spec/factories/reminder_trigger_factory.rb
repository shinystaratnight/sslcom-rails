# == Schema Information
#
# Table name: reminder_triggers
#
#  id         :integer          not null, primary key
#  name       :integer
#  created_at :datetime
#  updated_at :datetime
#

FactoryBot.define do
  factory :reminder_trigger do
    sequence(:name) { |n| n }
  end
end
