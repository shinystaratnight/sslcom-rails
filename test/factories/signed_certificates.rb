require './test/support/setup_helper'

FactoryGirl.define do
  factory :signed_certificate do
    common_name       'qlikdev.ezops.com'
    organization_unit ['Domain Control Validated']
    fingerprint       "--- !ruby/object:OpenSSL::BN {}\n"
    signature         '1E:DC:F8:1D:A3:70:32:D8:87:DE:3C:C4:AA:27:AE:98:97:DC:9C:7D'
    parent_cert       false
    strength          4096
    subject_alternative_names ['qlikdev.ezops.com', 'www.qlikdev.ezops.com']
  end

  trait :nonwildcard_csr do
    after :build do |sc|
      initialize_certificate_csr_keys
      sc.body = @nonwildcard_certificate.strip
    end
  end

  trait :nonwildcard_certificate_sslcom do
    after :build do |sc|
      initialize_certificate_csr_keys
      sc.body = @nonwildcard_certificate_sslcom.strip
    end
  end
end
