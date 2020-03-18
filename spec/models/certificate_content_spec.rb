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

require 'rails_helper'

describe CertificateContent do
  before :each do
    stub_roles
    stub_triggers
    stub_server_software
    SslAccount.any_instance.stubs(:initial_setup).returns(true)
  end

  it 'it calls certificate_names_from_domains after being saved' do
    certificate_content = create(:certificate_content)
    certificate_content.expects(:certificate_names_from_domains).returns(true)
    certificate_content.save
  end

  describe 'workflow states' do
    %i[new csr_submitted info_provided pending_validation validated pending_issuance issued canceled revoked].each do |state|
      it "should respond to with_#{state}_state" do
        expect(CertificateContent).to respond_to("with_#{state}_state".to_sym)
      end
    end
  end

  it { should  belong_to :certificate_order }
  it { should  belong_to :server_software }
  it { should  belong_to :ca }
  it { should  have_one :csr }
  it { should  have_one :ssl_account }
  it { should  have_one :registrant }
  it { should  have_one :locked_registrant }
  it { should  have_many :csrs }
  it { should  have_many :domain_control_validations }
  it { should  have_many :url_callbacks }
  it { should  have_many :taggings }
  it { should  have_many :tags }
  it { should  have_many :sslcom_ca_requests }
  it { should  have_many :attestation_certificates }
  it { should  have_many :attestation_issuer_certificates }
  it { should  have_many :certificate_names }
  it { should  have_many :certificate_contacts }
  it { should  have_many :signed_certificates }
  it { should  accept_nested_attributes_for(:certificate_contacts).allow_destroy(true) }
  it { should  accept_nested_attributes_for(:registrant).allow_destroy(false) }
  it { should  accept_nested_attributes_for(:csr).allow_destroy(false) }
end