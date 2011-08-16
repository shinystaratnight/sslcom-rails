FactoryGirl.define do
  factory :user do
    association :ssl_account
    roles {|roles|[roles.association(:role)]}
    after_create {|user|user.roles = [FactoryGirl.create(:role, name: "customer")]}
    #roles [FactoryGirl.create(:role, name: "customer")]
  end
  
  factory :registrant do
    association :contactable, :factory=>:certificate_content
  end
  
  factory :certificate_content do
    association :certificate_order
  end
  
  factory :certificate_order do
    has_csr false
    association :ssl_account
    association :sub_itemable, :factory=>:sub_order_item
  end
  
  factory :sub_order_item do
    association :product_variant_item
  end
  
  factory :funded_account do
    association :ssl_account
  end
  
  factory :product_variant_item do
    association :sub_itemable, :factory=>:certificate_order
  end
  
  #factory :reminder_trigger do
  #  rt.sequence(:id){|i|i}
  #end
  
  factory :ssl_account do
    preferred_reminder_notice_destinations '0'
    acct_number {'a'+ActiveSupport::SecureRandom.hex(1)+
          '-'+Time.now.to_i.to_s(32)}
  end

  factory :role do

  end
end


