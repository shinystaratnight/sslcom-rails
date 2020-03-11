# frozen_string_literal: true

# == Schema Information
#
# Table name: certificate_contents
#
#  id                   :integer          not null, primary key
#  agreement            :boolean
#  approval             :string(255)
#  billing_checkbox     :boolean
#  domains              :text(65535)
#  duration             :integer
#  ext_customer_ref     :string(255)
#  label                :string(255)
#  ref                  :string(255)
#  signed_certificate   :text(65535)
#  signing_request      :text(65535)
#  technical_checkbox   :boolean
#  validation_checkbox  :boolean
#  workflow_state       :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#  ca_id                :integer
#  certificate_order_id :integer          not null
#  server_software_id   :integer
#
# Indexes
#
#  index_certificate_contents_on_ca_id                 (ca_id)
#  index_certificate_contents_on_certificate_order_id  (certificate_order_id)
#  index_certificate_contents_on_ref                   (ref)
#  index_certificate_contents_on_server_software_id    (server_software_id)
#  index_certificate_contents_on_workflow_state        (workflow_state)
#

FactoryBot.define do
  factory :certificate_content do
    signing_request do
      "-----BEGIN CERTIFICATE REQUEST-----\r\nMIIChjCCAXACAQAwEzERMA8GA1UEAwwIdGVzdC5jb20wggEiMA0GCSqGSIb3DQEB\r\nAQUAA4IBDwAwggEKAoIBAQCudFpgjVUAfQjW1bjViVZ7SQ4IiTDAAadabdPrFCFX\r\n9bOKELFuB1MXBfu7gfi4bHntxhzUur6c7kUW38DE74qZujwgzQJBnzDmI5ZHTQ3G\r\n8d5RFDoyijtXgWSlxcfj7tu8cYyVMJ3hSDdHuhyUqOLEdeUQVBF3oYZXKYPs3Qxt\r\nwCzSPhz0966NSWIp08onERJB3IarVhuExWv7jGdHb6RQHR6/COQSCSt2fL8L2LR1\r\nzSZ909qsd2k+7Dy+5Yytb8uLGjC0g/RYYVaNFA5xP6x/jN1K3ot6WX/24jHW8ZFL\r\nCGUxG8pC8j8vPM4h+wGuaudG8g2T6utLGKs2VknLTFq/AgMBAAGgMDAuBgkqhkiG\r\n9w0BCQ4xITAfMB0GA1UdDgQWBBRrLTeK8UJ1bdckZMt0f5oSmCYBJjALBgkqhkiG\r\n9w0BAQsDggEBAKpM7t6MBmJ6PxtqNwG5ZpEr0sfTEiQ/btlm85y3AJCvS1cqoaoT\r\nsLRl20RBdqXcjVrbhQRigiLE8ui/FPoTGLA78ZgQoY22CxgvYjOxYQ48muyk14ss\r\n8fZYBtaC0fan2dbEgIepb0HB3KTgzJFbZasFBXJqUEgtp5MSpjs4ThYVvO/W8qeh\r\nSodUk5206DDkhLuCt5w3+ahLfeMMVQbomdjOGv5DWgWUGtDAos5+LGsPqGvNHFmD\r\nEFLutdbQIZ9/ZEk/MXpjDlHuVrlcmhQqRC3yGN0eBQVxM6VLFWLhuwJ/VcMUkqq6\r\npWS8V5LIS/aInvr+2nFIe+CosWUS3XXib8M=\r\n-----END CERTIFICATE REQUEST-----\r\n"
    end
    workflow_state { 'issued' }
    label { 'test.com1575479891145' }
    ref { 'co-ee1eufn55-0' }
    duration { 90 }

    csr
    certificate_order

    transient do
      include_tags { false }
    end

    after :create do |cc, options|
      if options.include_tags
        tag = create(:tag)
        tagging = Tagging.create(tag_id: tag[:id], taggable_id: cc.id, taggable_type: 'CertificateContent')
        cc.taggings << tagging
      end
    end
  end
end
