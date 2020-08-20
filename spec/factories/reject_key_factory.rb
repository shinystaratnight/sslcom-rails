FactoryBot.define do
  factory :reject_key do
    fingerprint { }
    algorithm { }
    size { }
    source { }

    factory :weak_key, parent: :reject_key do
     type { 'WeakKey' }
     algorithm { 'RSA' }
     source { 'blacklist-openssl' }
    end

    factory :compromised_key, parent: :reject_key do
      type { 'CompromiseKey' }
      algorithm { 'RSA' }
      source { 'key-compromise' }
     end

    trait :bit_2048 do
      sequence(:fingerprint) { |n| "00006aa0ce2cd60e666#{n}" }
      size { 2048 }
    end

    trait :bit_4096 do
      sequence(:fingerprint) { |n| "0000a8b95b4ccc411e6#{n}" }
      size { 4096 }
    end
  end
end
