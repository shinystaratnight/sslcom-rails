FactoryBot.define do
  factory :billing_profile do
    first_name        { 'first' }
    last_name         { 'last' }
    address_1         { '123 H St.' }
    country           {'United States'}
    city              {'Houston' }
    state             {'Texas'}
    postal_code       {'12345'}
    phone             {'9161223444'}
    credit_card       { 'Visa' }
    card_number       {BillingProfile.gateway_stripe? ? '4242424242424242' : '4007000000027'}
    expiration_month  {1}
    expiration_year   {(Date.today + 3.years).year}
    security_code     {'900'}
    default_profile   {1}
    status            {''}
    tax               {''}
    association :ssl_account, factory: :ssl_account
  end

  trait :expired do
    expiration_year   {Date.today.year - 1}
  end

  trait :declined do
    if BillingProfile.gateway_stripe?
      card_number {'4000000000000002'}
    else
      postal_code {'46282'} # Authorize.net general decline
    end
  end
end
