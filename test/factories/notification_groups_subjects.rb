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
FactoryBot.define do
  factory :notification_groups_subject do
    sequence(:domain_name) { |n| "testdomain#{n}.com" }

    trait :certificate_name_type do
      subjectable_type { 'CertificateName' }
    end

    trait :certificate_order_type do
      subjectable_type { 'CertificateOrder' }
    end

    trait :certificate_order_type do
      subjectable_type { 'CertificateContent' }
    end
  end
end
