FactoryBot.define do
  factory :phone_call_back_log do
    validated_by { Faker::Internet.username(specifier: 8..15) }
    cert_order_ref { "co-#{Faker::Alphanumeric.alphanumeric(number: 12)}" }
    phone_number { Faker::PhoneNumber.phone_number_with_country_code }
    validated_at { DateTime.now }
    certificate_order
  end
end
