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
    initialize_server_software
  end

  subject { build(:certificate_order) }

  context 'associations' do
    should belong_to(:assignee).class_name('User')
    should belong_to(:folder)
    should belong_to(:site_seal)
    should belong_to(:parent).class_name('CertificateOrder')
    should belong_to(:ssl_account)
    should belong_to(:validation)

    should have_many(:registrants).through(:certificate_contents)
    should have_many(:locked_registrants).through(:certificate_contents)
    should have_many(:certificate_contacts).through(:certificate_contents)
    should have_many(:domain_control_validations).through(:certificate_names)
    should have_many(:csrs).through(:certificate_contents).source(:csr)
    should have_many(:csr_unique_values).through(:csrs)
    should have_many(:attestation_certificates).through(:certificate_contents)

    should have_many(:signed_certificates).through(:csrs).source(:signed_certificate)
    should have_many(:attestation_issuer_certificates).through(:certificate_contents)
    should have_many(:shadow_certificates).through(:csrs).class_name('ShadowSignedCertificate')
    should have_many(:ca_certificate_requests).through(:csrs)
    should have_many(:ca_api_requests).through(:csrs)
    should have_many(:sslcom_ca_requests).through(:csrs)
    should have_many(:sub_order_items)
    should have_many(:product_variant_items).through(:sub_order_items)
    should have_many(:orders).through(:line_items)
    should have_many(:other_party_validation_requests).class_name('OtherPartyValidationRequest')
    should have_many(:ca_retrieve_certificates)
    should have_many(:ca_mdc_statuses)

    should have_many(:jois).class_name('Joi')
    should have_many(:app_reps).class_name('AppRep')
    should have_many(:physical_tokens)
    should have_many(:url_callbacks).through(:certificate_contents)
    should have_many(:taggings)
    should have_many(:tags).through(:taggings)
    should have_many(:notification_groups_subjects)
    should have_many(:notification_groups).through(:notification_groups_subjects)
    should have_many(:certificate_order_tokens)
    should have_many(:certificate_order_managed_csrs)
    should have_many(:managed_csrs).through(:certificate_order_managed_csrs)
    should have_many(:certificate_order_domains)
    should have_many(:managed_domains).through(:certificate_order_domains).source(:domain)

    should have_one(:locked_recipient)
    should have_one(:renewal)
  end

  context 'scopes' do
    # configurable_filters = [
    #   product: nil,
    #   is_test: true,
    #   order_by_csr: nil,
    #   physical_tokens: nil,
    #   notes: nil,
    #   ref: nil,
    #   external_order_number: nil,
    #   status: nil,
    #   duration: 365,
    #   co_tags: nil,
    #   cc_tags: nil,
    #   folder_ids: nil
    # ]

    describe 'search_with_csr' do
      let!(:cert) { create(:certificate_with_certificate_order) }
      let!(:co) { create(:certificate_order, sub_order_items: [cert.product_variant_groups[0].product_variant_items[0].sub_order_item]) }
      %w[common_name organization organization_unit state subject_alternative_names locality decoded].each do |field|
        it "filters by csr.#{field}" do
          co.certificate_contents << create(:certificate_content, include_csr: true, certificate_order_id: co.id)
          csr = co.certificate_contents[0].csrs[1]
          query = "#{field}:'#{csr[field.to_sym]}'"
          queried = CertificateOrder.search_with_csr(query)

          assert_equal(queried.include?(co), true)
        end
      end

      %w[postal_code signature fingerprint country strength address login email].each do |field|
        it "filters by signed_certificate.#{field}" do
          co.certificate_contents << create(:certificate_content, include_csr: true, certificate_order_id: co.id)
          sc = co.certificate_contents[0].csrs[1].signed_certificates[0]

          query = case field
                  when 'login'
                    co.ssl_account.users << create(:user)
                    "#{field}:'#{co.ssl_account.users[0][field.to_sym]}'"
                  when 'email'
                    co.ssl_account.users << create(:user)
                    "#{field}:'#{co.ssl_account.users[0][field.to_sym]}'"
                  when 'address'
                    "#{field}:'#{sc[:address1]}'"
                  else
                    "#{field}:'#{sc[field.to_sym]}'"
                  end
          puts query
          queried = CertificateOrder.search_with_csr(query)

          assert_equal(queried.include?(co), true)
        end
      end

      it 'filters by signed_certificate.expiration_date' do
        co = CertificateOrder.paid.create(sub_order_items: [cert.product_variant_groups[0].product_variant_items[0].sub_order_item])
        co.certificate_contents << create(:certificate_content, include_csr: true, certificate_order_id: co.id)
        start = DateTime.now.strftime('%m/%d/%Y')
        stop = (DateTime.now + 30.days).strftime('%m/%d/%Y')
        range = [start, stop].join('-')
        query = "expires_at:'#{range}'"
        queried = CertificateOrder.search_with_csr(query)

        assert_equal(queried.include?(co), true)
      end

      it 'filters by signed_certificate.created_at' do
        co = CertificateOrder.paid.create(sub_order_items: [cert.product_variant_groups[0].product_variant_items[0].sub_order_item])
        co.certificate_contents << create(:certificate_content, include_csr: true, certificate_order_id: co.id)
        start = (DateTime.now - 2.days).strftime('%m/%d/%Y')
        stop = (DateTime.now + 30.days).strftime('%m/%d/%Y')
        range = [start, stop].join('-')
        query = "issued_at:'#{range}'"
        queried = CertificateOrder.search_with_csr(query)

        assert_equal(queried.include?(co), true)
      end

      it 'filters by created_at' do
        co = CertificateOrder.paid.create(sub_order_items: [cert.product_variant_groups[0].product_variant_items[0].sub_order_item])
        co.certificate_contents << create(:certificate_content, include_csr: true, certificate_order_id: co.id)
        start = (DateTime.now - 2.days).strftime('%m/%d/%Y')
        stop = (DateTime.now + 30.days).strftime('%m/%d/%Y')
        range = [start, stop].join('-')
        query = "created_at:'#{range}'"
        queried = CertificateOrder.search_with_csr(query)

        assert_equal(queried.include?(co), true)
      end
    end
  end
end
