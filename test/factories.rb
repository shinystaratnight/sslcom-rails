require 'faker'

FactoryGirl.define do
  factory :user  do
    association :ssl_account
    roles {|roles|[roles.association(:role)]}

    factory :customer do
      after(:create) {|user|user.roles = [FactoryGirl.create(:role, name: Role::CUSTOMER)]}
    end

    factory :sysadmin do
      after(:create) {|user|user.roles = [FactoryGirl.create(:role, name: "sysadmin")]}
    end

    factory :reseller_user do
      after(:create) {|user|user.roles = [FactoryGirl.create(:role, name: Role::RESELLER)]}

      factory :tier_2_reseller do
        after(:create){|user|
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
    after(:create) {|c|
      create(:certificate_preference, owner: c)
    }

    factory :dv_certificate do
      product "free"
    end
    factory :ev_certificate do
      product "ev"
      serial "evucc256sslcom"
    end
    factory :wildcard_certificate do
      product "wildcard"
    end

    factory :basic_ssl do
      product "basicssl"
      serial "basic256sslcom"
      published_as "live"

      after(:create) do |c, evaluator|
        # create :basic_ssl_product_variant_group, variantable: c

        c.product_variant_groups << create(:basic_ssl_product_variant_group)
        # create_list :basic_ssl_product_variant_group, 1, variantable: c
      end
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
    server_software {ServerSoftware.where{title =~ "%java%"}.first}
    workflow_state "new"

    trait :standard_csr do
      csr {|c|c.association(:ssl_danskkabeltv_dk_2048_csr)}
    end

    factory :certificate_content_w_csr do
      workflow_state "csr_submitted"
      standard_csr

      factory :certificate_content_w_registrant do
        after(:create){|cc|FactoryGirl.create :registrant, contactable: cc}
        workflow_state "info_provided"

        factory :certificate_content_w_contacts do
          workflow_state "contacts_provided"
          after(:create) {|cc|
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
      # association :certificate, factory: :dv_certificate
      after(:build) do |co, evaluator|
        co.sub_order_items << create(:dv_sub_order_item)
      end
    end

    factory :new_dv_certificate_order do
      new
      dv
    end

    factory :completed_unvalidated_dv_certificate_order do
      paid
      dv
    end
  end

  factory :line_item do
    sellable { |i| i.association(:certificate_order) }
  end

  factory :order do
  end

  factory :csr do
    association :certificate_content

    trait :has_standard_signed_cert do
      signed_certificates {|sc|[sc.association(:signed_certificate)]}
    end

    factory :ssl_danskkabeltv_dk_2048_csr do
      has_standard_signed_cert
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
  end

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
    # sub_itemable { |i| i.association(:certificate_order) }
    # association :sub_itemable, factory: :new_dv_certificate_order

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

    factory :dv_product_variant_item do
      association :product_variant_group, factory: :dv_product_variant_group
    end

    factory :basic_ssl_product_variant_item do
      value "365"
      association :product_variant_group, factory: :basic_ssl_product_variant_group
    end
  end

  factory :product_variant_group do
    status "live"
    published_as "live"
    title "Duration"
    sequence(:display_order, 100)
    association :variantable, factory: :certificate

    factory :dv_product_variant_group do
      association :variantable, factory: :dv_certificate
    end

    factory :basic_ssl_product_variant_group do
      after(:create) do |pvg, evaluator|
        create_list :basic_ssl_product_variant_item, 1, product_variant_group: pvg
      end
    end
  end

  #factory :reminder_trigger do
  #  rt.sequence(:id){|i|i}
  #end

  #FactoryGirl.define do
  #  sequence :acct_number do |n|
  #    n #.to_s+SecureRandom.hex(1)+
  #          '-'+Time.now.to_i.to_s(32)
  #  end
  #end

  factory :ssl_account do
    preferred_reminder_notice_destinations '0'
    sequence :acct_number do |n|
      n.to_s+SecureRandom.hex(1)+'-'+Time.now.to_i.to_s(32)
    end

    factory :ssl_account_reseller do
      association :reseller
      after(:create) {|sa|
        sa.add_role! "reseller"
        sa.set_reseller_default_prefs
      }
      factory :ssl_account_reseller_tier_1 do
        association :reseller, factory: :reseller_reseller_tier_1
      end

      factory :ssl_account_reseller_tier_2 do
        after(:create) {|sa|
          FactoryGirl.create(:reseller, ssl_account: sa, reseller_tier: ResellerTier.find(2))}
      end
    end
  end

  factory :reseller_tier do

    factory :reseller_tier_1 do
      after(:create) do |tier, evaluator|
        create_list :reseller, 1, reseller_tier: tier
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

    factory :reseller_reseller_tier_1 do
      association :reseller_tier, factory: :reseller_tier_1
    end

  end

  factory :role do

  end

  factory :other_party_validation_request do
  end

  factory :signed_certificate do
    body <<-EOS
-----BEGIN CERTIFICATE-----
MIIF8TCCBNmgAwIBAgIRAIhAUCbwe96rLRlCxal/S8MwDQYJKoZIhvcNAQEFBQAw
gYkxCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAO
BgNVBAcTB1NhbGZvcmQxGjAYBgNVBAoTEUNPTU9ETyBDQSBMaW1pdGVkMS8wLQYD
VQQDEyZDT01PRE8gSGlnaC1Bc3N1cmFuY2UgU2VjdXJlIFNlcnZlciBDQTAeFw0x
MTA0MTUwMDAwMDBaFw0xNDA0MTQyMzU5NTlaMIIBADELMAkGA1UEBhMCREsxDTAL
BgNVBBETBDI2MjAxEzARBgNVBAgTCkNvcGVuaGFnZW4xFDASBgNVBAcTC0FsYmVy
dHNsdW5kMRYwFAYDVQQJEw1Sb2hvbG1zdmVqIDE5MRswGQYDVQQKExJEYW5zayBL
YWJlbCBUViBBL1MxEjAQBgNVBAsTCUludGVybiBJVDEzMDEGA1UECxMqSG9zdGVk
IGJ5IFNlY3VyZSBTb2NrZXRzIExhYm9yYXRvcmllcywgTExDMRowGAYDVQQLExFD
b21vZG8gSW5zdGFudFNTTDEdMBsGA1UEAxMUY2FwYS5kYW5za2thYmVsdHYuZGsw
ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC1P4LoIL5aK4NULdr+N/EK
yf6HOZvha862euuuXtZrmWzCU2DIcJltQLOaqh6EdAl7CdOqEV2OO18Yz8aVpWOF
aACFz3Y1G3xYa/l9mVM/WLU01eFCHExSHJwl6ClYEjdGZnqcvTNWgV7+cQrBRgT1
dD5P9UCHJ89LXY0gsuMCIgXgy7UJf3qK9tjqYfgXfF3A67y62wCutY6BlnQ9Rxaj
lvLnDFMG5ikiAENJYvqSTec3XM61bmMbxodFb2LxYNXW62BEHXew+ROIwhDHS3aH
HxCASh9lGc+gD+BTb+PqkW4/i6ZKeFojStvgXFU6KO6WFxZlrY2lSd+YBiHuPTtT
AgMBAAGjggHYMIIB1DAfBgNVHSMEGDAWgBQ/1bXQ1kR5UEoXo5uMSty4sCJkazAd
BgNVHQ4EFgQUol7CxsiPp3niNZ7ahxCo34ZwsnswDgYDVR0PAQH/BAQDAgWgMAwG
A1UdEwEB/wQCMAAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMEYGA1Ud
IAQ/MD0wOwYMKwYBBAGyMQECAQMEMCswKQYIKwYBBQUHAgEWHWh0dHBzOi8vc2Vj
dXJlLmNvbW9kby5jb20vQ1BTME8GA1UdHwRIMEYwRKBCoECGPmh0dHA6Ly9jcmwu
Y29tb2RvY2EuY29tL0NPTU9ET0hpZ2gtQXNzdXJhbmNlU2VjdXJlU2VydmVyQ0Eu
Y3JsMIGABggrBgEFBQcBAQR0MHIwSgYIKwYBBQUHMAKGPmh0dHA6Ly9jcnQuY29t
b2RvY2EuY29tL0NPTU9ET0hpZ2gtQXNzdXJhbmNlU2VjdXJlU2VydmVyQ0EuY3J0
MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5jb20wOQYDVR0RBDIw
MIIUY2FwYS5kYW5za2thYmVsdHYuZGuCGHd3dy5jYXBhLmRhbnNra2FiZWx0di5k
azANBgkqhkiG9w0BAQUFAAOCAQEAzONarfSOGna5wXOXhS9+t3Rh65Cd/dVJz2Ak
8biAQKVNc5XEzCDSnvKPFIUE+IFYi1f0jsd3RWVI3VUSlwwdB6MijCINuWLTrBi1
IbfulbWwPZ+ZrgdM6Vv4MJ2KUH/RMxkQwpHWdoFPZibS69m45xHCkwzgRkaXFXqq
HolkkgHVQi+XfSEUfWssi7OdWvPSEKakhS3zHdeaNm9IkKl4lo6Yee4mT/cY4TKn
A3XqCNBvjA3l3JOwlqjrm+Cus2xwg//XWE7T6XUbI/L5U6FMbV9E8gmKyhfYSQ2n
dp6YRn8XDWkkbOWgSCHfQGqD52BCZ82ZsAziZun+pSwYDNNSdg==
-----END CERTIFICATE-----
    EOS
  end

  factory :preference do
    factory :certificate_preference do
      name "certificate_chain"
      value "AddTrustExternalCARoot.crt:Root CA Certificate, UTNAddTrustServerCA.crt:Intermediate CA Certificate"
    end
  end

  factory :duplicate_v2_user do

  end

  factory :api_certificate_create do
    account_key "000000"
    period "365"
    server_software "1"
    secret_key "000000"
    #TODO make not required if dv
    organization_name "Acme"
    street_address_1 "123 Oak Dr"
    locality_name "Pal Alot"
    state_or_province_name "CA"
    postal_code "00000"
    country_name "US"
    product "200"
    is_customer_validated "true"
    csr <<EOS
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

    factory :api_certificate_create_invalid_account_key do
      account_key "00001"
    end
  end

  factory :api_credential do
    account_key "000000"
    secret_key "000000"
    association :ssl_account, factory: :ssl_account_reseller_tier_1
  end
end


