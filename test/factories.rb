FactoryGirl.define do
  factory :user  do
    association :ssl_account
    roles {|roles|[roles.association(:role)]}

    factory :customer do
      after_create {|user|user.roles = [FactoryGirl.create(:role, name: Role::CUSTOMER)]}
    end

    factory :sysadmin do
      after_create {|user|user.roles = [FactoryGirl.create(:role, name: "sysadmin")]}
    end

    factory :reseller_user do
      after_create {|user|user.roles = [FactoryGirl.create(:role, name: Role::RESELLER)]}

      factory :tier_2_reseller do
        after_create{|user|
          user.ssl_account=FactoryGirl.create(:ssl_account_reseller_tier_2)
          user.save
        }
      end
    end
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

  factory :certificate_contact do
    first_name "Billy"
    last_name "Bob"
    email "bb@example.com"
    phone "123-456-7890"
    association :contactable, :factory=>:certificate_content

    factory :billing_certificate_contact do
      roles ["billing"]
    end
    factory :administrative_certificate_contact do
      roles ["administrative"]
    end
    factory :technical_certificate_contact do
      roles ["technical"]
    end
    factory :business_certificate_contact do
      roles ["business"]
    end
  end

  factory :certificate_content do
    association :certificate_order
    server_software {ServerSoftware.where(:title =~ "%java%").first}

    factory :certificate_content_w_csr do
      association :csr

      factory :certificate_content_w_registrant do
        after_create{|cc|FactoryGirl.create :registrant, contactable: cc}

        factory :certificate_content_w_contacts do
          workflow_state "contacts_provided"
          after_create {|cc|
            FactoryGirl.create(:billing_certificate_contact, contactable: cc)
            FactoryGirl.create(:administrative_certificate_contact, contactable: cc)
            FactoryGirl.create(:business_certificate_contact, contactable: cc)
            FactoryGirl.create(:technical_certificate_contact, contactable: cc)
          }

          factory :certificate_content_pending_validation do
            workflow_state "pending_validation"
          end
        end
      end
    end
  end
  
  factory :certificate_order do
    has_csr false
    association :ssl_account
    orders{|orders|[orders.association(:order)]}

    trait :new do
      workflow_state "new"
    end

    trait :paid do
      workflow_state "paid"
    end

    trait :dv do
      after_build do |co|
        si=FactoryGirl.create(:dv_sub_order_item,
          sub_itemable: co)
        co.sub_order_items << si
      end
    end

    factory :new_dv_certificate_order do
      new
      dv

      factory :completed_unvalidated_dv_certificate_order do
        paid
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
MIIC6jCCAdICAQAwgaQxCzAJBgNVBAYTAkRLMRMwEQYDVQQIEwpDb3BlbmhhZ2Vu
MRQwEgYDVQQHEwtBbGJlcnRzbHVuZDEPMA0GA1UECxMGVGVrbmlrMRcwFQYDVQQK
Ew5EYW5zayBLYWJlbCBUVjEcMBoGA1UEAxMTc3NsLmRhbnNra2FiZWx0di5kazEi
MCAGCSqGSIb3DQEJARYTc2xoQGRhbnNra2FiZWx0di5kazCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBANG+v2MNf5oD/iQhOuKlBzJRqAFHMj3KuKejfw29
eubsO+PATjwJAoyuN+smnlSjzL8or6Yb1wNaBPbDY3OprO4+KJ7tgMfxnqScrbdi
RuqbhFy2WOs/UmsMyP0Eb7GSf2dPktgvhK8h5Y8lsGpZFpWj05CdewdFYD2THz9f
uonFBk0OsaMKu48wE9exT0PsdtSG5Z2bEYs24gHO4IgqyKtSSsciUBghx161NBX/
1d6xwiXwv25SKEOr2vww/IYUGvfIKZNHDcren2PShmSUE+WW5uTeY18Lbzs51Gxh
MTjRZvrI9VSoxYp3hjh/CIpuIDL/ACe/3Ht90nQ3RAXz0PsCAwEAAaAAMA0GCSqG
SIb3DQEBBQUAA4IBAQDFxzw9pi2agvF6bRl1RxyinfnBLVrZcszp07rEf+D6sLcE
m/hEPcd5cisk/NAOU1YrWZPBmVxyQeNP/9t22P98cZvVxGam257/D/hKLCFvT6O+
8qR/i6wAl19BMX0jLMODNkXHRMHq4v/Uv9DkpejcwvqzcrH2EbKL/ZYgM4e7CtlK
Sv4v5KfdNucQPgoaWB76OFkqmVsLTZAeFhT9+R8c1kXAeaqWk5wSYVyJVofFG5Ox
dqdBYOw9UwEsiFwYYMk6XSRXDPA9ldBYqgb/ck/BxFVFzdLg2p8plZWjuhqcNI9E
wJ4W0jbRq+eaj9c10Q3cPAT65yYggar+AKD7Gr+H
-----END CERTIFICATE REQUEST-----
EOS

  factory :wildcard_csr do
    body <<EOS
-----BEGIN CERTIFICATE REQUEST-----
MIIC0TCCAbkCAQAwgYsxCzAJBgNVBAYTAnVzMQ8wDQYDVQQIEwZPcmVnb24xETAP
BgNVBAcTCFBvcnRsYW5kMRswGQYDVQQKExJDcm93ZCBGYWN0b3J5IEluYy4xGTAX
BgNVBAsTEE9wZXJhdGlvbnMgR3JvdXAxIDAeBgNVBAMMFyouY29ycC5jcm93ZGZh
Y3RvcnkuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAq5f0CVkd
zR6lMoI/ejRvK/8Q+TLOk9SEyKxAx9hpmwf8+qLnt5Et6w1gplpqgjREQj6LMpcj
99gNoRTfkGGu+AO23wOPjmknAPHUEHAoPR3JIv643Dk4vTXGTLTAeoi5equEaq5l
6iz32UtSpROBHPRJjVHg/wC/UkolDT2tfhVOYELyzTW44OkWaVAgvjLEXEu2Wq2J
LZuShvfA6dPHfpgfZVAQD1/ucnlkbDXaGcb/vldgirEND8OvA0uufuKFUOjd+NdQ
eCCxHgN5YiKax4EMZ5Xu3BQK1XNkcbee8pW/fdhPX8ZpraoamgjU1aFfW9GGiKpH
JSl/u5EkcYFl/wIDAQABoAAwDQYJKoZIhvcNAQEFBQADggEBAJiiuHHG3sIfZqqd
J1MYS1S8pp9z8fzwEagl1PseGpr4tzqdI/YyAmsKbJ/5Vcjl7omnH5EbjbrWHxnT
HI/yD9iYzys5APRYuWTsu2062E1oBuqCUZlambofM3OJ3ZOaqKDMuKPOYaZXZ5oa
wo5DnhHydWM5oueaWbMuLv8ydbqolP+MrBhbA8CQp+nlwsxeJHyFhJINL0Ewb/GE
oMFCVp27p9bIE35qpNqOaYAcLxp6wTFTPRg048vpYbZxNfwV07uMTJnge7YdQ9KP
yMi36slJID403aJwthhX8cwWVOLpbBjDG9gcucR1l3TSDW8QVWDMari4ih5mIIQP
xMajgLU=
-----END CERTIFICATE REQUEST-----
EOS
  end
  end
  
  factory :sub_order_item do
    sub_itemable { |i| i.association(:certificate_order) }

    trait :dv do
      association :product_variant_item, factory: :dv_product_variant_item
    end

    factory :dv_sub_order_item do
      dv
    end
  end
  
  factory :funded_account do
    association :ssl_account
  end
  
  factory :product_variant_item do
    association :product_variant_group
    sequence(:display_order, 100)
    status "live"
  
    factory :dv_product_variant_item, class: "ProductVariantItem" do |pvi|
      pvi.product_variant_group{|product_variant_group|
        product_variant_group.association(:product_variant_group, variantable:
            Certificate.where(product: "free").first)}#FactoryGirl.create(:dv_certificate))}
    end
  end

  factory :product_variant_group do
    status "live"
    sequence(:display_order, 100)
    association :variantable, factory: :certificate
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

    factory :ssl_account_reseller do
      after_create {|sa|
        sa.add_role! "reseller"
        sa.set_reseller_default_prefs
      }
      factory :ssl_account_reseller_tier_1 do
        after_create {|sa|
          sa.reseller_tier=ResellerTier.find(1)
          sa.save}
      end
      factory :ssl_account_reseller_tier_2 do
        after_create {|sa|
          FactoryGirl.create(:reseller, ssl_account: sa, reseller_tier: ResellerTier.find(2))}
      end
    end
  end

  factory :reseller do
    type_organization Reseller::BUSINESS
    organization "Acme Inc"
    website "www.example.com"
    address1 "123 Abc St"
    postal_code 12345
    city "Some City"
    state "NY"
    tax_number "123-45-1234"
    country "US"
    first_name "Billy"
    last_name "Bob"
    email "someone@example.com"
    phone "111-111-1111"
    association :ssl_account
  end

  factory :role do

  end

  factory :other_party_validation_request do
  end
end


