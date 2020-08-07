FactoryBot.define do
  factory :certificate_order_token do
    callback_datetime { DateTime.now + 1.day }
    callback_method { 'call' }
    callback_timezone {}
    callback_type {}
    due_date { DateTime.now + 1.week }
    is_callback_done {}
    is_expired { false }
    locale { 'en' }
    passed_token { }
    phone_call_count { 0 }
    phone_number {}
    phone_verification_count { 0 }
    status { 'pending' }
    token { Faker::Alphanumeric.alpha(number: 10) }
    certificate_order

    trait :manual do
      callback_type { 'manual' }
    end
  end
end
