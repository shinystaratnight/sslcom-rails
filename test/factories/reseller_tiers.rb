FactoryBot.define do
  factory :reseller_tier do
    published_as {'live'}
    label        {'1'}
    amount       { 0}
    roles        {'tier_1_reseller'}
    description  {{ideal_for: 'pay as you go'}}

    trait :professional do
      label        {'2'}
      amount       { 20000}
      roles        {'tier_2_reseller'}
      description  {{ideal_for: 'professionals'}}
    end

    trait :medium_business do
      label        {'3'}
      amount        {100000}
      roles        {'tier_3_reseller'}
      description  {{ideal_for: 'small to medium sized businesses'}}
    end

    trait :large_business do
      label       { '4'}
      amount        {500000}
      roles        {'tier_4_reseller'}
      description  {{ideal_for: 'large businesses'}}
    end

    trait :enterprise do
      label       { '5'}
      amount        {2000000}
      roles        {'tier_5_reseller'}
      description  {{ideal_for: 'enterprise organizations'}}
    end
  end
end
