# frozen_string_literal: true

module X509Helper
  def create_x509_cert(domain)
    key = OpenSSL::PKey::RSA.new(1024)
    public_key = key.public_key

    subject = "/C=BE/O=Test/OU=Test/CN=#{domain}"

    cert = OpenSSL::X509::Certificate.new
    cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)

    cert.not_before = Time.now + 365
    cert.not_after = Time.now
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
    cert
  end
end
