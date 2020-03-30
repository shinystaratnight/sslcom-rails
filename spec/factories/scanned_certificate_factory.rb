# == Schema Information
#
# Table name: scanned_certificates
#
#  id         :integer          not null, primary key
#  body       :text(65535)
#  decoded    :text(65535)
#  serial     :string(255)
#  created_at :datetime
#  updated_at :datetime
#

require 'openssl'

FactoryBot.define do
  factory :scanned_certificate do
    trait :wont_expire_soon do
      key = OpenSSL::PKey::RSA.new(1024)
      public_key = key.public_key

      subject = '/C=BE/O=Test/OU=Test/CN=Test'

      cert = OpenSSL::X509::Certificate.new
      cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
      cert.not_before = Time.zone.now
      cert.not_after = Time.zone.now + 365.days
      cert.public_key = public_key
      cert.serial = Faker::Number.number(digits: 20)
      cert.version = 2

      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = cert
      ef.issuer_certificate = cert
      cert.extensions = [
        ef.create_extension('basicConstraints', 'CA:TRUE', true),
        ef.create_extension('subjectKeyIdentifier', 'hash')
      ]
      cert.add_extension ef.create_extension('authorityKeyIdentifier',
                                             'keyid:always,issuer:always')

      cert.sign key, OpenSSL::Digest::SHA1.new

      serial { cert.serial }
      decoded { cert.to_text }
      body { cert.to_s }
    end

    trait :expired_today do
      key = OpenSSL::PKey::RSA.new(1024)
      public_key = key.public_key

      subject = '/C=BE/O=Test/OU=Test/CN=Test'

      cert = OpenSSL::X509::Certificate.new
      cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
      cert.not_before = Time.zone.now
      cert.not_after = Time.zone.now
      cert.public_key = public_key
      cert.serial = Faker::Number.number(digits: 20)
      cert.version = 2

      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = cert
      ef.issuer_certificate = cert
      cert.extensions = [
        ef.create_extension('basicConstraints', 'CA:TRUE', true),
        ef.create_extension('subjectKeyIdentifier', 'hash')
      ]
      cert.add_extension ef.create_extension('authorityKeyIdentifier',
                                             'keyid:always,issuer:always')

      cert.sign key, OpenSSL::Digest::SHA1.new

      serial { cert.serial }
      decoded { cert.to_text }
      body { cert.to_s }
    end

    trait :expired_15_days_ago do
      key = OpenSSL::PKey::RSA.new(1024)
      public_key = key.public_key

      subject = '/C=BE/O=Test/OU=Test/CN=Test'

      cert = OpenSSL::X509::Certificate.new
      cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
      cert.not_before = Time.zone.now
      cert.not_after = Time.zone.now - 15.days
      cert.public_key = public_key
      cert.serial = Faker::Number.number(digits: 20)
      cert.version = 2

      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = cert
      ef.issuer_certificate = cert
      cert.extensions = [
        ef.create_extension('basicConstraints', 'CA:TRUE', true),
        ef.create_extension('subjectKeyIdentifier', 'hash')
      ]
      cert.add_extension ef.create_extension('authorityKeyIdentifier',
                                             'keyid:always,issuer:always')

      cert.sign key, OpenSSL::Digest::SHA1.new

      serial { cert.serial }
      decoded { cert.to_text }
      body { cert.to_s }
    end

    trait :expires_in_30_days do
      key = OpenSSL::PKey::RSA.new(1024)
      public_key = key.public_key

      subject = '/C=BE/O=Test/OU=Test/CN=Test'

      cert = OpenSSL::X509::Certificate.new
      cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
      cert.not_before = Time.zone.now
      cert.not_after = Time.zone.now + 30.days
      cert.public_key = public_key
      cert.serial = Faker::Number.number(digits: 20)
      cert.version = 2

      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = cert
      ef.issuer_certificate = cert
      cert.extensions = [
        ef.create_extension('basicConstraints', 'CA:TRUE', true),
        ef.create_extension('subjectKeyIdentifier', 'hash')
      ]
      cert.add_extension ef.create_extension('authorityKeyIdentifier',
                                             'keyid:always,issuer:always')

      cert.sign key, OpenSSL::Digest::SHA1.new

      serial { cert.serial }
      decoded { cert.to_text }
      body { cert.to_s }
    end

    trait :expires_in_15_days do
      key = OpenSSL::PKey::RSA.new(1024)
      public_key = key.public_key

      subject = '/C=BE/O=Test/OU=Test/CN=Test'

      cert = OpenSSL::X509::Certificate.new
      cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
      cert.not_before = Time.zone.now
      cert.not_after = Time.zone.now + 15.days
      cert.public_key = public_key
      cert.serial = Faker::Number.number(digits: 20)
      cert.version = 2

      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = cert
      ef.issuer_certificate = cert
      cert.extensions = [
        ef.create_extension('basicConstraints', 'CA:TRUE', true),
        ef.create_extension('subjectKeyIdentifier', 'hash')
      ]
      cert.add_extension ef.create_extension('authorityKeyIdentifier',
                                             'keyid:always,issuer:always')

      cert.sign key, OpenSSL::Digest::SHA1.new

      serial { cert.serial }
      decoded { cert.to_text }
      body { cert.to_s }
    end

    trait :expires_in_60_days do
      key = OpenSSL::PKey::RSA.new(1024)
      public_key = key.public_key

      subject = '/C=BE/O=Test/OU=Test/CN=Test'

      cert = OpenSSL::X509::Certificate.new
      cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
      cert.not_before = Time.zone.now
      cert.not_after = Time.zone.now + 60.days
      cert.public_key = public_key
      cert.serial = Faker::Number.number(digits: 20)
      cert.version = 2

      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = cert
      ef.issuer_certificate = cert
      cert.extensions = [
        ef.create_extension('basicConstraints', 'CA:TRUE', true),
        ef.create_extension('subjectKeyIdentifier', 'hash')
      ]
      cert.add_extension ef.create_extension('authorityKeyIdentifier',
                                             'keyid:always,issuer:always')

      cert.sign key, OpenSSL::Digest::SHA1.new

      serial { cert.serial }
      decoded { cert.to_text }
      body { cert.to_s }
    end
  end
end
