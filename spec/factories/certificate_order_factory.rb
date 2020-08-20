# frozen_string_literal: true
FactoryBot.define do
  factory :certificate_order do
    workflow_state { 'paid' }
    ref { 'co-ee1eufn55' }
    amount { '11000' }
    ca { 'SSLcomSHA2' }
    ssl_account
    external_order_number { Faker::Alphanumeric.alphanumeric(number: 12) }
    notes { Faker::Lorem.paragraph }

    transient do
      include_tags { false }
      true_build { false }
    end

    trait :with_contents do
      after :create do |co|
        create(:certificate_content, certificate_order_id: co[:id])
      end
    end

    after :create do |co, options|
      co.taggings << Tagging.create(tag: create(:tag, ssl_account: co.ssl_account), taggable_id: co.id, taggable_type: 'CertificateOrder') if options.include_tags
    end

    after :stub do |co|
      co.stubs(:sub_order_items).returns(build_stubbed(:sub_order_item))
      co.stubs(:certificate).returns(build_stubbed(:certificate))
    end
  end
end
