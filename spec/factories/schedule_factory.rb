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
