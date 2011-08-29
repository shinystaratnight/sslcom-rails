FactoryGirl.define do
  factory :user do
    association :ssl_account
    roles {|roles|[roles.association(:role)]}
    after_create {|user|user.roles = [FactoryGirl.create(:role, name: "customer")]}
  end
  
  #factory :registrant do
  #  association :contactable, :factory=>:certificate_content
  #end

  factory :certificate do
    factory :dv_certificate do
      product "free"
    end
    factory :ev_certificate do
      product "ev"
    end
    factory :wildcard_certificate do
      product "wildcard"
    end
  end

  factory :server_software do
  end

  factory :registrant do
    company_name "Betsoftgaming LTD."
    address1 "someplace"
    city "Strovolos"
    state "Nicosia"
    postal_code "00000"
    country "CY"
    association :contactable, :factory=>:certificate_content
  end

  factory :certificate_content do
    association :certificate_order
    association :csr
    server_software {ServerSoftware.where(:title =~ "%java%").first}

    factory :certificate_content_w_registrant do
      after_create{|cc|FactoryGirl.create :registrant, contactable: cc}

      factory :certificate_content_w_contacts do
        workflow_state "contacts_provided"
      end
    end
  end
  
  factory :certificate_order do
    has_csr false
    association :ssl_account
    #association :sub_order_item
    orders{|orders|[orders.association(:order)]}

    factory :dv_certificate_order do
      after_create do |co|
        FactoryGirl.create(:sub_order_item,
          sub_itemable: co,
          product_variant_item:
            FactoryGirl.create(:dv_product_variant_item))
      end
    end
  end

  factory :line_item do
    sellable { |i| i.association(:certificate_order) }
  end

  factory :order do
  end

  factory :csr do
    body <<EOS
-----BEGIN CERTIFICATE REQUEST-----
MIIBtTCCAR4CAQAwdTELMAkGA1UEBhMCQ1kxEDAOBgNVBAgTB05pY29zaWExEjAQ
BgNVBAcTCVN0cm92b2xvczEbMBkGA1UEChMSQmV0c29mdGdhbWluZyBMVEQuMSMw
IQYDVQQDExpsb2JieS5zYi5iZXRzb2Z0Z2FtaW5nLmNvbTCBnzANBgkqhkiG9w0B
AQEFAAOBjQAwgYkCgYEAsrTRXbve5Y7dhSorB11hIkHqbKZgxbDPQ2w0BacHIx2U
7M1RtyXaPYizUXHOrjCiCoe9NyivZ9Oip63kfIb5vpArIgVfnM2K2aizcmi6pdj2
kbePrp1Uz86nxxbEso013XWlmu2lgTRTeBETeRFebYzSKH7hHvFR37kaQRIdHckC
AwEAAaAAMA0GCSqGSIb3DQEBBQUAA4GBADAknB7B/3CnvuZUJrH5O6oD3USft4QU
uuMti01ffH4ZyTMfyLdDcd0gdeXPej+JGvScuXPjzpMb92cpfufTRKsTBUG1C2T6
TYrJ9O3d5oKph8nICihGT0fDIqJCzGar6W9ZbL8PiIDL4hFymVUZk409NPfrND1g
yIeY8v/sjOUW
-----END CERTIFICATE REQUEST-----
EOS
  end
  
  factory :sub_order_item do
    sub_itemable { |i| i.association(:certificate_order) }
    association :product_variant_item
  end
  
  factory :funded_account do
    association :ssl_account
  end
  
  factory :product_variant_item do
    association :product_variant_group
  end
  
  factory :dv_product_variant_item, class: "ProductVariantItem" do |pvi|
    pvi.product_variant_group{|product_variant_group|
      product_variant_group.association(:product_variant_group, variantable:
          Certificate.where(product: "free").first)}#FactoryGirl.create(:dv_certificate))}
  end

  factory :product_variant_group do
    variantable { |i| i.association(:certificate) }
  end

  #factory :reminder_trigger do
  #  rt.sequence(:id){|i|i}
  #end

  #FactoryGirl.define do
  #  sequence :acct_number do |n|
  #    n #.to_s+ActiveSupport::SecureRandom.hex(1)+
  #          '-'+Time.now.to_i.to_s(32)
  #  end
  #end

  factory :ssl_account do
    preferred_reminder_notice_destinations '0'
    sequence :acct_number do |n|
      n.to_s+ActiveSupport::SecureRandom.hex(1)+'-'+Time.now.to_i.to_s(32)
    end
  end

  factory :role do

  end
end


