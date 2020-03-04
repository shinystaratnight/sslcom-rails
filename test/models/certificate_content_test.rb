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

require 'test_helper'

describe CertificateContent do
  before :all do
    stub_roles
    stub_triggers
    stub_server_software
  end
  subject{ build_stubbed(:certificate_content) }

  it 'it calls certificate_names_from_domains after being saved' do
    certificate_content = create(:certificate_content)
    certificate_content.expects(:certificate_names_from_domains).returns(true)
    certificate_content.save
  end

  describe 'workflow states' do
    %i[new csr_submitted info_provided pending_validation validated pending_issuance issued canceled revoked].each do |state|
      it "has #{state} state" do
        assert_respond_to CertificateContent, "with_#{state}_state"
      end
    end
  end

  describe 'associations' do
    should belong_to :certificate_order
    should belong_to :server_software
    should belong_to :ca
    should have_one :csr
    should have_one :ssl_account
    should have_one :registrant
    should have_one :locked_registrant
    should have_many :csrs
    should have_many :domain_control_validations
    should have_many :url_callbacks
    should have_many :taggings
    should have_many :tags
    should have_many :sslcom_ca_requests
    should have_many :attestation_certificates
    should have_many :attestation_issuer_certificates
    should have_many :certificate_names
    should have_many :certificate_contacts
    should have_many :signed_certificates

    should accept_nested_attributes_for(:certificate_contacts).allow_destroy(true)
    should accept_nested_attributes_for(:registrant).allow_destroy(false)
    should accept_nested_attributes_for(:csr).allow_destroy(false)
  end
end
