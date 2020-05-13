FactoryBot.define do
  factory :csr_unique_value do
    unique_value { Faker::Lorem.characters(number: 10) }
    csr
  end
end
