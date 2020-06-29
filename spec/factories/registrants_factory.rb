FactoryBot.define do
  factory :registrant do
    title { Faker::Name.prefix }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    company_name { Faker::Name.name }
    department { "I.T." }
    po_box { }
    address1 {Faker::Address.street_address}
    address2 { }
    address3 { }
    city { Faker::Address.city }
    state { Faker::Address.state }
    country { Faker::Address.country }
    postal_code { Faker::Address.postcode }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.phone_number }
    ext { }
    fax { }
    notes { }
    type { 'Registrant' }
    roles { '--- []' }
    registrant_type { 1 }
    parent_id { }
    callback_method { }
    incorporation_date { }
    incorporation_country { }
    incorporation_state { }
    incorporation_city { }
    assumed_name { }
    business_category { Faker::Company.type }
    duns_number { Faker::Company.duns_number }
    company_number { }
    registration_service { }
    saved_default { false }
    status { 1 }
    user_id { }
    special_fields { }
    domains { }
    country_code { "1" }
    workflow_state { "new" }
    phone_number_approved { true }
  end

  factory :locked_registrant, parent: :registrant do
    type { "LockedRegistrant" }
  end
end
