# frozen_string_literal: true
require 'rails_helper'

describe CertificateContent do
  it 'calls certificate_names_from_domains after being saved' do
    certificate_content = create(:certificate_content)
    certificate_content.expects(:certificate_names_from_domains).returns(true)
    certificate_content.skip_validation = true
    certificate_content.save
  end

  describe 'workflow states' do
    %i[new csr_submitted info_provided pending_validation validated pending_issuance issued canceled revoked].each do |state|
      it "responds to with_#{state}_state" do
        expect(described_class).to respond_to("with_#{state}_state".to_sym)
      end
    end
  end

  it { is_expected.to  belong_to :certificate_order }
  it { is_expected.to  belong_to :server_software }
  it { is_expected.to  belong_to :ca }
  it { is_expected.to  have_one :csr }
  it { is_expected.to  have_one :ssl_account }
  it { is_expected.to  have_one :registrant }
  it { is_expected.to  have_one :locked_registrant }
  it { is_expected.to  have_many :csrs }
  it { is_expected.to  have_many :domain_control_validations }
  it { is_expected.to  have_many :url_callbacks }
  it { is_expected.to  have_many :taggings }
  it { is_expected.to  have_many :tags }
  it { is_expected.to  have_many :sslcom_ca_requests }
  it { is_expected.to  have_many :attestation_certificates }
  it { is_expected.to  have_many :attestation_issuer_certificates }
  it { is_expected.to  have_many :certificate_names }
  it { is_expected.to  have_many :certificate_contacts }
  it { is_expected.to  have_many :signed_certificates }
  it { is_expected.to  accept_nested_attributes_for(:certificate_contacts).allow_destroy(true) }
  it { is_expected.to  accept_nested_attributes_for(:registrant).allow_destroy(false) }
  it { is_expected.to  accept_nested_attributes_for(:csr).allow_destroy(false) }
end
