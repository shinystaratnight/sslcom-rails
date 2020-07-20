FactoryBot.define do
  factory :verification do
    association :user

    factory :all_verifications do
      sms_number { 1234567890 }
      sms_prefix { Faker::PhoneNumber.country_code }
      call_number { 1234567890 }
      call_prefix { Faker::PhoneNumber.country_code }
      email { Faker::Internet.email }
    end

    factory :sms_verification do
      sms_number { 1234567890 }
      sms_prefix { Faker::PhoneNumber.country_code }
    end

    factory :call_verification do
      call_number { 1234567890 }
      call_prefix { Faker::PhoneNumber.country_code }
    end

    factory :email_verification do
      email { Faker::Internet.email }
    end
  end
end
