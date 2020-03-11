# frozen_string_literal: true

# == Schema Information
#
# Table name: signed_certificates
#
#  id                        :integer          not null, primary key
#  address1                  :string(255)
#  address2                  :string(255)
#  body                      :text(65535)
#  common_name               :string(255)
#  country                   :string(255)
#  decoded                   :text(65535)
#  effective_date            :datetime
#  ejbca_username            :string(255)
#  expiration_date           :datetime
#  ext_customer_ref          :string(255)
#  fingerprint               :string(255)
#  fingerprintSHA            :string(255)
#  locality                  :string(255)
#  organization              :string(255)
#  organization_unit         :text(65535)
#  parent_cert               :boolean
#  postal_code               :string(255)
#  revoked_at                :datetime
#  serial                    :text(65535)      not null
#  signature                 :text(65535)
#  state                     :string(255)
#  status                    :text(65535)      not null
#  strength                  :integer
#  subject_alternative_names :text(65535)
#  type                      :string(255)
#  url                       :string(255)
#  created_at                :datetime
#  updated_at                :datetime
#  ca_id                     :integer
#  certificate_content_id    :integer
#  certificate_lookup_id     :integer
#  csr_id                    :integer
#  parent_id                 :integer
#  registered_agent_id       :integer
#
# Indexes
#
#  index_signed_certificates_cn_u_b_d_ecf_eu            (common_name,url,body,decoded,ext_customer_ref,ejbca_username)
#  index_signed_certificates_on_3_cols                  (common_name,strength)
#  index_signed_certificates_on_ca_id                   (ca_id)
#  index_signed_certificates_on_certificate_content_id  (certificate_content_id)
#  index_signed_certificates_on_certificate_lookup_id   (certificate_lookup_id)
#  index_signed_certificates_on_common_name             (common_name)
#  index_signed_certificates_on_csr_id                  (csr_id)
#  index_signed_certificates_on_csr_id_and_type         (csr_id,type)
#  index_signed_certificates_on_ejbca_username          (ejbca_username)
#  index_signed_certificates_on_fingerprint             (fingerprint)
#  index_signed_certificates_on_id_and_type             (id,type)
#  index_signed_certificates_on_parent_id               (parent_id)
#  index_signed_certificates_on_registered_agent_id     (registered_agent_id)
#  index_signed_certificates_on_strength                (strength)
#  index_signed_certificates_t_cci                      (type,certificate_content_id)
#
# Foreign Keys
#
#  fk_rails_...  (ca_id => cas.id) ON DELETE => restrict ON UPDATE => restrict
#

require './test/support/setup_helper'

FactoryBot.define do
  factory :signed_certificate do
    address1 { Faker::Address.street_address }
    address2 { Faker::Address.secondary_address }
    common_name { 'qlikdev.ezops.com' }
    country { Faker::Address.country }
    expiration_date { 90.days.from_now }
    locality { Faker::Address.city }
    state { Faker::Address.state }
    status { 'issued' }
    organization { 'Test Organization' }
    organization_unit { ['Domain Control Validated', 'Hosted by Secure Sockets Laboratories'] }
    signature        { '1E:DC:F8:1D:A3:70:32:D8:87:DE:3C:C4:AA:27:AE:98:97:DC:9C:7D' }
    parent_cert      { false }
    strength         { 4096 }
    subject_alternative_names { ['qlikdev.ezops.com', 'www.qlikdev.ezops.com'] }
    postal_code { Faker::Address.zip_code }
    body do
      "-----BEGIN CERTIFICATE-----\nMIIE7zCCA9egAwIBAgIRAKhhZGkICqv+mDKnO9Af2IUwDQYJKoZIhvcNAQELBQAw\nTTELMAkGA1UEBhMCVVMxEDAOBgNVBAoTB1NTTC5jb20xFDASBgNVBAsTC3d3dy5z\nc2wuY29tMRYwFAYDVQQDEw1TU0wuY29tIERWIENBMB4XDTE2MTIyOTAwMDAwMFoX\nDTE4MDMyNTIzNTk1OVowcTEhMB8GA1UECxMYRG9tYWluIENvbnRyb2wgVmFsaWRh\ndGVkMS4wLAYDVQQLEyVIb3N0ZWQgYnkgU2VjdXJlIFNvY2tldHMgTGFib3JhdG9y\naWVzMRwwGgYDVQQDExNteC5rZ25jb25zdWx0aW5nLnNlMIIBIjANBgkqhkiG9w0B\nAQEFAAOCAQ8AMIIBCgKCAQEA1EDurepCZgGuH4tdq55RF9r/NySPP6D68YJ60q89\nhZcWIIGAgzpvJpTGWjjs9+WH9SjQQptNKQwboZR/Y+oucC2mOSKBb00mM38RBvAj\nizy3HSL5dWTonfQfJ+K7qhbYrbF0ubh7bVJB5FTxnDkYLhKLhV4ScHHdavXyUh5V\n3XYecFWqPaz8jUUxEdT0hAM2dzHydO3Wzm6RjiiCI2nsK5FYEEfVP589gbH3NBB3\nwTCPz9mSzYzluRYb7k5fbZ4/atGlq03UFAoiaVLpO944BH09RxH/Vra/87lc42h0\na1oK3zvnmvSHcMoqW6yWuMp8zH3UEv9jIaPE5MvglU9Y4QIDAQABo4IBpDCCAaAw\nHwYDVR0jBBgwFoAURpr9/FFefFRTUuKZ47My75Maf1YwHQYDVR0OBBYEFOzGFmqd\nQegBVNH/0ViFRh81e8fWMA4GA1UdDwEB/wQEAwIFoDAMBgNVHRMBAf8EAjAAMB0G\nA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjBKBgNVHSAEQzBBMDUGCisGAQQB\ngqkwAQEwJzAlBggrBgEFBQcCARYZaHR0cHM6Ly9jcHMudXNlcnRydXN0LmNvbTAI\nBgZngQwBAgEwNAYDVR0fBC0wKzApoCegJYYjaHR0cDovL2NybC5zc2wuY29tL1NT\nTGNvbURWQ0FfMi5jcmwwYAYIKwYBBQUHAQEEVDBSMC8GCCsGAQUFBzAChiNodHRw\nOi8vY3J0LnNzbC5jb20vU1NMY29tRFZDQV8yLmNydDAfBggrBgEFBQcwAYYTaHR0\ncDovL29jc3Auc3NsLmNvbTA9BgNVHREENjA0ghNteC5rZ25jb25zdWx0aW5nLnNl\ngh1hdXRvZGlzY292ZXIua2duY29uc3VsdGluZy5zZTANBgkqhkiG9w0BAQsFAAOC\nAQEAi6CyJplNbBys7MYO1EzqpsSMyiQSx8t7IOTce4FQ4VO/ZEzlrovsEd1prPxA\n/o3OKIETI1TO2Lz2GUvCeyz8oux8K1cTj0E7WtVtjaTMlgsWUr5P9T+/EqVpYqlO\nsu1GMp+cuR7/H2F8LAGbBlq3REInxiX2qHFJ2Bpv7xOss7CEjQUnDS9xlTT357x6\n3AYlMtECLCbebY2JrctFUGBb5kT7PiEJ5urn4vA/Sdft5tsZOlPFOOv172mlzc6S\nYzDbDoFh4VvBDZldNWXE2JjQ9Sd82a2Qe5m+sAXdHSSgvS3GsAI1s9Uir/3GNVGn\nIr0a4aRQHEk0SUe8wQpgGa2Trg==\n-----END CERTIFICATE-----"
    end
    decoded do
      "Certificate:\n    Data:\n        Version: 3 (0x2)\n        Serial Number:\n            a8:61:64:69:08:0a:ab:fe:98:32:a7:3b:d0:1f:d8:85\n    Signature Algorithm: sha256WithRSAEncryption\n        Issuer: C=US, O=SSL.com, OU=www.ssl.com, CN=SSL.com DV CA\n        Validity\n            Not Before: Dec 29 00:00:00 2016 GMT\n            Not After : Mar 25 23:59:59 2018 GMT\n        Subject: OU=Domain Control Validated, OU=Hosted by Secure Sockets Laboratories, CN=mx.kgnconsulting.se\n        Subject Public Key Info:\n            Public Key Algorithm: rsaEncryption\n                Public-Key: (2048 bit)\n                Modulus:\n                    00:d4:40:ee:ad:ea:42:66:01:ae:1f:8b:5d:ab:9e:\n                    51:17:da:ff:37:24:8f:3f:a0:fa:f1:82:7a:d2:af:\n                    3d:85:97:16:20:81:80:83:3a:6f:26:94:c6:5a:38:\n                    ec:f7:e5:87:f5:28:d0:42:9b:4d:29:0c:1b:a1:94:\n                    7f:63:ea:2e:70:2d:a6:39:22:81:6f:4d:26:33:7f:\n                    11:06:f0:23:8b:3c:b7:1d:22:f9:75:64:e8:9d:f4:\n                    1f:27:e2:bb:aa:16:d8:ad:b1:74:b9:b8:7b:6d:52:\n                    41:e4:54:f1:9c:39:18:2e:12:8b:85:5e:12:70:71:\n                    dd:6a:f5:f2:52:1e:55:dd:76:1e:70:55:aa:3d:ac:\n                    fc:8d:45:31:11:d4:f4:84:03:36:77:31:f2:74:ed:\n                    d6:ce:6e:91:8e:28:82:23:69:ec:2b:91:58:10:47:\n                    d5:3f:9f:3d:81:b1:f7:34:10:77:c1:30:8f:cf:d9:\n                    92:cd:8c:e5:b9:16:1b:ee:4e:5f:6d:9e:3f:6a:d1:\n                    a5:ab:4d:d4:14:0a:22:69:52:e9:3b:de:38:04:7d:\n                    3d:47:11:ff:56:b6:bf:f3:b9:5c:e3:68:74:6b:5a:\n                    0a:df:3b:e7:9a:f4:87:70:ca:2a:5b:ac:96:b8:ca:\n                    7c:cc:7d:d4:12:ff:63:21:a3:c4:e4:cb:e0:95:4f:\n                    58:e1\n                Exponent: 65537 (0x10001)\n        X509v3 extensions:\n            X509v3 Authority Key Identifier: \n                keyid:46:9A:FD:FC:51:5E:7C:54:53:52:E2:99:E3:B3:32:EF:93:1A:7F:56\n\n            X509v3 Subject Key Identifier: \n                EC:C6:16:6A:9D:41:E8:01:54:D1:FF:D1:58:85:46:1F:35:7B:C7:D6\n            X509v3 Key Usage: critical\n                Digital Signature, Key Encipherment\n            X509v3 Basic Constraints: critical\n                CA:FALSE\n            X509v3 Extended Key Usage: \n                TLS Web Server Authentication, TLS Web Client Authentication\n            X509v3 Certificate Policies: \n                Policy: 1.3.6.1.4.1.38064.1.1\n                  CPS: https://cps.usertrust.com\n                Policy: 2.23.140.1.2.1\n\n            X509v3 CRL Distribution Points: \n\n                Full Name:\n                  URI:http://crl.ssl.com/SSLcomDVCA_2.crl\n\n            Authority Information Access: \n                CA Issuers - URI:http://crt.ssl.com/SSLcomDVCA_2.crt\n                OCSP - URI:http://ocsp.ssl.com\n\n            X509v3 Subject Alternative Name: \n                DNS:mx.kgnconsulting.se, DNS:autodiscover.kgnconsulting.se\n    Signature Algorithm: sha256WithRSAEncryption\n         8b:a0:b2:26:99:4d:6c:1c:ac:ec:c6:0e:d4:4c:ea:a6:c4:8c:\n         ca:24:12:c7:cb:7b:20:e4:dc:7b:81:50:e1:53:bf:64:4c:e5:\n         ae:8b:ec:11:dd:69:ac:fc:40:fe:8d:ce:28:81:13:23:54:ce:\n         d8:bc:f6:19:4b:c2:7b:2c:fc:a2:ec:7c:2b:57:13:8f:41:3b:\n         5a:d5:6d:8d:a4:cc:96:0b:16:52:be:4f:f5:3f:bf:12:a5:69:\n         62:a9:4e:b2:ed:46:32:9f:9c:b9:1e:ff:1f:61:7c:2c:01:9b:\n         06:5a:b7:44:42:27:c6:25:f6:a8:71:49:d8:1a:6f:ef:13:ac:\n         b3:b0:84:8d:05:27:0d:2f:71:95:34:f7:e7:bc:7a:dc:06:25:\n         32:d1:02:2c:26:de:6d:8d:89:ad:cb:45:50:60:5b:e6:44:fb:\n         3e:21:09:e6:ea:e7:e2:f0:3f:49:d7:ed:e6:db:19:3a:53:c5:\n         38:eb:f5:ef:69:a5:cd:ce:92:63:30:db:0e:81:61:e1:5b:c1:\n         0d:99:5d:35:65:c4:d8:98:d0:f5:27:7c:d9:ad:90:7b:99:be:\n         b0:05:dd:1d:24:a0:bd:2d:c6:b0:02:35:b3:d5:22:af:fd:c6:\n         35:51:a7:22:bd:1a:e1:a4:50:1c:49:34:49:47:bc:c1:0a:60:\n         19:ad:93:ae\n"
    end
  end
end
