FactoryBot.define do
  factory :billing_profile do
    first_name        { Faker::Name.first_name }
    last_name         { Faker::Name.last_name }
    address_1         { Faker::Address.street_address }
    country           { 'United States' }
    city              { Faker::Address.city }
    state             { Faker::Address.state }
    postal_code       { Faker::Address.zip_code }
    phone             { Faker::PhoneNumber.phone_number }
    credit_card       { 'Visa' }
    card_number       { BillingProfile.gateway_stripe? ? '4242424242424242' : '4007000000027' }
    expiration_month  { 1 }
    expiration_year   { (Time.zone.today + 3.years).year }
    security_code     { '900' }
    default_profile   { 1 }
    status            { '' }
    tax               { '' }
    association :ssl_account, factory: :ssl_account
  end

  trait :expired do
    expiration_year { Time.zone.today.year - 1 }
  end

  trait :declined do
    if BillingProfile.gateway_stripe?
      card_number { '4000000000000002' }
    else
      postal_code { '46282' } # Authorize.net general decline
    end
  end
end
