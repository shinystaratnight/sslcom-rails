FactoryGirl.define do
  factory :billing_profile do
    first_name        'first'
    last_name         'last'
    address_1         '123 H St.'
    country           'United States'
    city              'Houston'
    state             'Texas'
    postal_code       '12345'
    phone             '9161223444'
    credit_card       'Visa'
    card_number       '4007000000027'
    expiration_month  1
    expiration_year   {(Date.today + 3.years).year}
    security_code     '900' 
  end
end
