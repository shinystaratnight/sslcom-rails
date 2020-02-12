# frozen_string_literal: true

# == Schema Information
#
# Table name: csrs
#
#  id                        :integer          not null, primary key
#  body                      :text(65535)
#  challenge_password        :boolean
#  common_name               :string(255)
#  country                   :string(255)
#  decoded                   :text(65535)
#  duration                  :integer
#  email                     :string(255)
#  ext_customer_ref          :string(255)
#  friendly_name             :string(255)
#  locality                  :string(255)
#  modulus                   :text(65535)
#  organization              :string(255)
#  organization_unit         :string(255)
#  public_key_md5            :string(255)
#  public_key_sha1           :string(255)
#  public_key_sha256         :string(255)
#  ref                       :string(255)
#  sig_alg                   :string(255)
#  state                     :string(255)
#  strength                  :integer
#  subject_alternative_names :text(65535)
#  created_at                :datetime
#  updated_at                :datetime
#  certificate_content_id    :integer
#  certificate_lookup_id     :integer
#  ssl_account_id            :integer
#
# Indexes
#
#  index_csrs_cn_b_d                                     (common_name,body,decoded)
#  index_csrs_on_3_cols                                  (common_name,email,sig_alg)
#  index_csrs_on_certificate_content_id                  (certificate_content_id)
#  index_csrs_on_certificate_lookup_id                   (certificate_lookup_id)
#  index_csrs_on_common_name                             (common_name)
#  index_csrs_on_common_name_and_certificate_content_id  (certificate_content_id,common_name)
#  index_csrs_on_common_name_and_email_and_sig_alg       (common_name,email,sig_alg)
#  index_csrs_on_organization                            (organization)
#  index_csrs_on_sig_alg_and_common_name_and_email       (sig_alg,common_name,email)
#  index_csrs_on_ssl_account_id                          (ssl_account_id)
#

FactoryBot.define do
  factory :csr do
    body do
      "-----BEGIN CERTIFICATE REQUEST-----\nMIIChjCCAXACAQAwEzERMA8GA1UEAwwIdGVzdC5jb20wggEiMA0GCSqGSIb3DQEB\r\nAQUAA4IBDwAwggEKAoIBAQCudFpgjVUAfQjW1bjViVZ7SQ4IiTDAAadabdPrFCFX\r\n9bOKELFuB1MXBfu7gfi4bHntxhzUur6c7kUW38DE74qZujwgzQJBnzDmI5ZHTQ3G\r\n8d5RFDoyijtXgWSlxcfj7tu8cYyVMJ3hSDdHuhyUqOLEdeUQVBF3oYZXKYPs3Qxt\r\nwCzSPhz0966NSWIp08onERJB3IarVhuExWv7jGdHb6RQHR6/COQSCSt2fL8L2LR1\r\nzSZ909qsd2k+7Dy+5Yytb8uLGjC0g/RYYVaNFA5xP6x/jN1K3ot6WX/24jHW8ZFL\r\nCGUxG8pC8j8vPM4h+wGuaudG8g2T6utLGKs2VknLTFq/AgMBAAGgMDAuBgkqhkiG\r\n9w0BCQ4xITAfMB0GA1UdDgQWBBRrLTeK8UJ1bdckZMt0f5oSmCYBJjALBgkqhkiG\r\n9w0BAQsDggEBAKpM7t6MBmJ6PxtqNwG5ZpEr0sfTEiQ/btlm85y3AJCvS1cqoaoT\r\nsLRl20RBdqXcjVrbhQRigiLE8ui/FPoTGLA78ZgQoY22CxgvYjOxYQ48muyk14ss\r\n8fZYBtaC0fan2dbEgIepb0HB3KTgzJFbZasFBXJqUEgtp5MSpjs4ThYVvO/W8qeh\r\nSodUk5206DDkhLuCt5w3+ahLfeMMVQbomdjOGv5DWgWUGtDAos5+LGsPqGvNHFmD\r\nEFLutdbQIZ9/ZEk/MXpjDlHuVrlcmhQqRC3yGN0eBQVxM6VLFWLhuwJ/VcMUkqq6\r\npWS8V5LIS/aInvr+2nFIe+CosWUS3XXib8M=\n-----END CERTIFICATE REQUEST-----\n"
    end
    common_name { Faker::Internet.domain_name }
    country { Faker::Address.country }
    decoded do
      'Certificate Request:
    Data:
        Version: 1 (0x0)
        Subject: CN=test.com
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:ae:74:5a:60:8d:55:00:7d:08:d6:d5:b8:d5:89:
                    56:7b:49:0e:08:89:30:c0:01:a7:5a:6d:d3:eb:14:
                    21:57:f5:b3:8a:10:b1:6e:07:53:17:05:fb:bb:81:
                    f8:b8:6c:79:ed:c6:1c:d4:ba:be:9c:ee:45:16:df:
                    c0:c4:ef:8a:99:ba:3c:20:cd:02:41:9f:30:e6:23:
                    96:47:4d:0d:c6:f1:de:51:14:3a:32:8a:3b:57:81:
                    64:a5:c5:c7:e3:ee:db:bc:71:8c:95:30:9d:e1:48:
                    37:47:ba:1c:94:a8:e2:c4:75:e5:10:54:11:77:a1:
                    86:57:29:83:ec:dd:0c:6d:c0:2c:d2:3e:1c:f4:f7:
                    ae:8d:49:62:29:d3:ca:27:11:12:41:dc:86:ab:56:
                    1b:84:c5:6b:fb:8c:67:47:6f:a4:50:1d:1e:bf:08:
                    e4:12:09:2b:76:7c:bf:0b:d8:b4:75:cd:26:7d:d3:
                    da:ac:77:69:3e:ec:3c:be:e5:8c:ad:6f:cb:8b:1a:
                    30:b4:83:f4:58:61:56:8d:14:0e:71:3f:ac:7f:8c:
                    dd:4a:de:8b:7a:59:7f:f6:e2:31:d6:f1:91:4b:08:
                    65:31:1b:ca:42:f2:3f:2f:3c:ce:21:fb:01:ae:6a:
                    e7:46:f2:0d:93:ea:eb:4b:18:ab:36:56:49:cb:4c:
                    5a:bf
                Exponent: 65537 (0x10001)
        Attributes:
        Requested Extensions:
            X509v3 Subject Key Identifier: 
                6B:2D:37:8A:F1:42:75:6D:D7:24:64:CB:74:7F:9A:12:98:26:01:26
    Signature Algorithm: sha256WithRSAEncryption
         aa:4c:ee:de:8c:06:62:7a:3f:1b:6a:37:01:b9:66:91:2b:d2:
         c7:d3:12:24:3f:6e:d9:66:f3:9c:b7:00:90:af:4b:57:2a:a1:
         aa:13:b0:b4:65:db:44:41:76:a5:dc:8d:5a:db:85:04:62:82:
         22:c4:f2:e8:bf:14:fa:13:18:b0:3b:f1:98:10:a1:8d:b6:0b:
         18:2f:62:33:b1:61:0e:3c:9a:ec:a4:d7:8b:2c:f1:f6:58:06:
         d6:82:d1:f6:a7:d9:d6:c4:80:87:a9:6f:41:c1:dc:a4:e0:cc:
         91:5b:65:ab:05:05:72:6a:50:48:2d:a7:93:12:a6:3b:38:4e:
         16:15:bc:ef:d6:f2:a7:a1:4a:87:54:93:9d:b4:e8:30:e4:84:
         bb:82:b7:9c:37:f9:a8:4b:7d:e3:0c:55:06:e8:99:d8:ce:1a:
         fe:43:5a:05:94:1a:d0:c0:a2:ce:7e:2c:6b:0f:a8:6b:cd:1c:
         59:83:10:52:ee:b5:d6:d0:21:9f:7f:64:49:3f:31:7a:63:0e:
         51:ee:56:b9:5c:9a:14:2a:44:2d:f2:18:dd:1e:05:05:71:33:
         a5:4b:15:62:e1:bb:02:7f:55:c3:14:92:aa:ba:a5:64:bc:57:
         92:c8:4b:f6:88:9e:fa:fe:da:71:48:7b:e0:a8:b1:65:12:dd:
         75:e2:6f:c3'
    end
    locality { Faker::Address.city }
    subject_alternative_names { [Faker::Internet.domain_name, Faker::Internet.domain_name] }
    state { Faker::Address.state }
    organization { 'Test Organization' }
    organization_unit { 'Marketing' }
    public_key_sha1 { 'b86dc8288b3e41bb751fc5a93011be53469fff83' }
    ref { 'csr-381eufn95' }
    strength { 2048 }

    transient do
      signed { false }
    end

    after :create do |csr, options|
      csr.signed_certificates << create(:signed_certificate, csr: csr) if options.signed
    end
  end
end
