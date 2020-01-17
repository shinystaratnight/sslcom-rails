# == Schema Information
#
# Table name: certificate_contents
#
#  id                   :integer          not null, primary key
#  certificate_order_id :integer          not null
#  signing_request      :text(65535)
#  signed_certificate   :text(65535)
#  server_software_id   :integer
#  domains              :text(65535)
#  duration             :integer
#  workflow_state       :string(255)
#  billing_checkbox     :boolean
#  validation_checkbox  :boolean
#  technical_checkbox   :boolean
#  created_at           :datetime
#  updated_at           :datetime
#  label                :string(255)
#  ref                  :string(255)
#  agreement            :boolean
#  ext_customer_ref     :string(255)
#  approval             :string(255)
#  ca_id                :integer
#

FactoryBot.define do
  factory :certificate_content do
    signing_request {
      "-----BEGIN CERTIFICATE REQUEST-----\r\nMIIChjCCAXACAQAwEzERMA8GA1UEAwwIdGVzdC5jb20wggEiMA0GCSqGSIb3DQEB\r\nAQUAA4IBDwAwggEKAoIBAQCudFpgjVUAfQjW1bjViVZ7SQ4IiTDAAadabdPrFCFX\r\n9bOKELFuB1MXBfu7gfi4bHntxhzUur6c7kUW38DE74qZujwgzQJBnzDmI5ZHTQ3G\r\n8d5RFDoyijtXgWSlxcfj7tu8cYyVMJ3hSDdHuhyUqOLEdeUQVBF3oYZXKYPs3Qxt\r\nwCzSPhz0966NSWIp08onERJB3IarVhuExWv7jGdHb6RQHR6/COQSCSt2fL8L2LR1\r\nzSZ909qsd2k+7Dy+5Yytb8uLGjC0g/RYYVaNFA5xP6x/jN1K3ot6WX/24jHW8ZFL\r\nCGUxG8pC8j8vPM4h+wGuaudG8g2T6utLGKs2VknLTFq/AgMBAAGgMDAuBgkqhkiG\r\n9w0BCQ4xITAfMB0GA1UdDgQWBBRrLTeK8UJ1bdckZMt0f5oSmCYBJjALBgkqhkiG\r\n9w0BAQsDggEBAKpM7t6MBmJ6PxtqNwG5ZpEr0sfTEiQ/btlm85y3AJCvS1cqoaoT\r\nsLRl20RBdqXcjVrbhQRigiLE8ui/FPoTGLA78ZgQoY22CxgvYjOxYQ48muyk14ss\r\n8fZYBtaC0fan2dbEgIepb0HB3KTgzJFbZasFBXJqUEgtp5MSpjs4ThYVvO/W8qeh\r\nSodUk5206DDkhLuCt5w3+ahLfeMMVQbomdjOGv5DWgWUGtDAos5+LGsPqGvNHFmD\r\nEFLutdbQIZ9/ZEk/MXpjDlHuVrlcmhQqRC3yGN0eBQVxM6VLFWLhuwJ/VcMUkqq6\r\npWS8V5LIS/aInvr+2nFIe+CosWUS3XXib8M=\r\n-----END CERTIFICATE REQUEST-----\r\n"
    }
    workflow_state { "issued" }
    label { "test.com1575479891145" }
    ref {"co-ee1eufn55-0"}
    duration {90}
  end
end
