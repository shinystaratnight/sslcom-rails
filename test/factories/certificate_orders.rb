# frozen_string_literal: true

# == Schema Information
#
# Table name: certificate_orders
#
#  id                    :integer          not null, primary key
#  ssl_account_id        :integer
#  validation_id         :integer
#  site_seal_id          :integer
#  workflow_state        :string(255)
#  ref                   :string(255)
#  num_domains           :integer
#  server_licenses       :integer
#  line_item_qty         :integer
#  amount                :integer
#  notes                 :text(65535)
#  created_at            :datetime
#  updated_at            :datetime
#  is_expired            :boolean
#  renewal_id            :integer
#  is_test               :boolean
#  auto_renew            :string(255)
#  auto_renew_status     :string(255)
#  ca                    :string(255)
#  external_order_number :string(255)
#  ext_customer_ref      :string(255)
#  validation_type       :string(255)
#  acme_account_id       :string(255)
#  wildcard_count        :integer
#  nonwildcard_count     :integer
#  folder_id             :integer
#  assignee_id           :integer
#  expires_at            :datetime
#  request_status        :string(255)
#

FactoryBot.define do
  factory :certificate_order do
    workflow_state { 'paid' }
    ref { 'co-ee1eufn55' }
    amount { '11000' }
    ca { 'SSLcomSHA2' }
    ssl_account
    external_order_number { Faker::Alphanumeric.alphanumeric(number: 12) }
    notes { Faker::Lorem.paragraph }

    transient do
      include_tags { false }
    end

    after :create do |co, options|
      if options.include_tags
        tagging = Tagging.create(tag: create(:tag), taggable_id: co.id, taggable_type: 'CertificateOrder')
        co.taggings << tagging
      end
    end
  end
end
