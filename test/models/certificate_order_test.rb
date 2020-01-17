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

require 'test_helper'

describe CertificateOrder do
  before(:all) do
    initialize_roles
    initialize_triggers
  end

  describe 'search_with_csr scope' do
    # configurable_filters = [
    #   common_name: "'#{Faker::Internet.domain_name}'",
    #   organization: "'#{Faker::Company.name}'",
    #   organization_unit: "'#{Faker::Commerce.department}'",
    #   address: "'#{Faker::Address.street_address}'",
    #   state: "'#{Faker::Address.state}'",
    #   postal_code: "'#{Faker::Address.postcode}'",
    #   subject_alternative_names: nil,
    #   locality: "'#{Faker::Address.city}'",
    #   country: "'#{Faker::Address.country}'",
    #   signature: nil,
    #   fingerprint: nil,
    #   strength: nil,
    #   expires_at: "'#{300.days.from_now}'",
    #   login: nil,
    #   email: "'#{Faker::Internet.email}'",
    #   product: nil,
    #   decoded: true,
    #   is_test: true,
    #   order_by_csr: nil,
    #   physical_tokens: nil,
    #   issued_at: nil,
    #   notes: nil,
    #   ref: nil,
    #   external_order_number: nil,
    #   status: nil,
    #   duration: 365,
    #   co_tags: nil,
    #   cc_tags: nil,
    #   folder_ids: nil
    # ]

    it 'filters by csr.common_name' do
      common_name = Faker::Internet.domain_name
      cert = create(:certificate_with_certificate_order)
      co = CertificateOrder.unscoped.create(sub_order_items: [cert.product_variant_groups[0].product_variant_items[0].sub_order_item])
      co.certificate_contents << create(:certificate_content, certificate_order_id: co.id, csrs: [create(:csr, common_name: common_name)])
      query = "common_name:#{common_name}"
      queried = CertificateOrder.search_with_csr(query)

      puts "queried: #{queried.presence || 'nil'}"
      puts JSON.dump(co.certificate_contents.first.csr.common_name)
      assert_equal(queried.include?(co), true)
    end
  end
end
