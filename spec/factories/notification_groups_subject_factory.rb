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
