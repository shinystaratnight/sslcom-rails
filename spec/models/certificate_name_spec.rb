# frozen_string_literal: true

# == Schema Information
# Schema version: 20200311011643
#
# Table name: certificate_names
#
#  id                     :integer          not null, primary key
#  acme_token             :string(255)
#  caa_passed             :boolean          default("0")
#  email                  :string(255)
#  is_common_name         :boolean
#  name                   :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  acme_account_id        :string(255)
#  certificate_content_id :integer
#  ssl_account_id         :integer
#
# Indexes
#
#  index_certificate_names_on_acme_token              (acme_token)
#  index_certificate_names_on_certificate_content_id  (certificate_content_id)
#  index_certificate_names_on_name                    (name)
#  index_certificate_names_on_ssl_account_id          (ssl_account_id)
#

require 'rails_helper'

describe CertificateName do
  before do
    stub_roles
    stub_triggers
    stub_server_software
  end

  it_behaves_like 'it filters on domain'

  it { is_expected.to have_db_column :id }
  it { is_expected.to have_db_column :acme_token }
  it { is_expected.to have_db_column :caa_passed }
  it { is_expected.to have_db_column :email }
  it { is_expected.to have_db_column :is_common_name }
  it { is_expected.to have_db_column :name }
  it { is_expected.to have_db_column :created_at }
  it { is_expected.to have_db_column :updated_at }
  it { is_expected.to have_db_column :acme_account_id }
  it { is_expected.to have_db_column :certificate_content_id }
  it { is_expected.to have_db_column :ssl_account_id }

  it { is_expected.to belong_to :certificate_content }
  it { is_expected.to have_one :certificate_order }
  it { is_expected.to have_many    :signed_certificates }
  it { is_expected.to have_many    :caa_checks }
  it { is_expected.to have_many    :ca_certificate_requests }
  it { is_expected.to have_many    :ca_dcv_requests }
  it { is_expected.to have_many    :ca_dcv_resend_requests }
  it { is_expected.to have_many    :validated_domain_control_validations }
  it { is_expected.to have_many    :last_sent_domain_control_validations }
  it { is_expected.to have_one :domain_control_validation }
  it { is_expected.to have_many :domain_control_validations }

  describe 'ACME support' do
    describe '.generate_acme_token' do
      let!(:certificate_name){ build(:certificate_name) }

      before do
        described_class.stubs(:exists?).returns(false)
      end

      it 'is 128 characters long' do
        certificate_name.generate_acme_token
        expect(certificate_name.acme_token.length). to eq 128
      end

      it 'does not have = padding' do
        certificate_name.generate_acme_token
        expect(certificate_name.acme_token).not_to match(/=$/)
      end

      it 'is url safe' do
        certificate_name.generate_acme_token
        expect(certificate_name.acme_token).to match(/^[a-zA-Z0-9_-]*$/)
      end
    end

    describe 'fail dcv' do
      before do
        logger = mock
        ApplicationService.any_instance.stubs(:logger).returns(logger)
        logger.stubs(:debug).returns(true)
      end

      let!(:certificate_name){ create(:certificate_name, :with_dcv) }

      it 'does not update workflow_state for http' do
        certificate_name.domain_control_validation.update(dcv_method: 'http')
        stub_request(:any, certificate_name.dcv_url(true, '', true))
          .to_return(status: 200, body: ['------------', '------------', '------------'])
        expect{ certificate_name.dcv_verify }.not_to change { certificate_name.domain_control_validation.workflow_state }
      end

      it 'does not update workflow_state for https' do
        stub_request(:any, certificate_name.dcv_url(true, '', true))
          .to_return(status: 200, body: ['------------', '------------', '------------'])
        expect{ certificate_name.dcv_verify }.not_to change { certificate_name.domain_control_validation.workflow_state }
      end

      it 'does not update workflow_state for cname' do
        certificate_name.domain_control_validation.update(dcv_method: 'cname')
        stub_request(:any, certificate_name.dcv_url(true, '', true))
          .to_return(status: 200, body: ['------------', '------------', '------------'])
        expect{ certificate_name.dcv_verify }.not_to change { certificate_name.domain_control_validation.workflow_state }
      end

      it 'updates workflow_state to failed for acme_http' do
        certificate_name.domain_control_validation.update(dcv_method: 'acme_http')
        body = [certificate_name.acme_token, '------------'].join('.')
        AcmeManager::HttpVerifier.any_instance.stubs(:challenge).returns(body)
        expect{ certificate_name.dcv_verify }.to change { certificate_name.domain_control_validation.workflow_state }.to('failed')
      end

      it 'updates workflow_state to failed for acme_dns_txt' do
        certificate_name.domain_control_validation.update(dcv_method: 'acme_dns_txt')
        body = Resolv::DNS::Resource::IN::TXT.new('------------')
        AcmeManager::DnsTxtVerifier.any_instance.stubs(:challenge).returns(true)
        AcmeManager::DnsTxtVerifier.any_instance.stubs(:token).returns(body.strings.last)
        expect{ certificate_name.dcv_verify }.to change { certificate_name.domain_control_validation.workflow_state }.to('failed')
      end
    end
  end

  describe 'domain control validation' do
    let!(:cname) { build_stubbed(:certificate_name) }

    before do
      cname.stubs(:fail_dcv).returns(false)
      cname.stubs(:satify_dcv).returns(true)
      cname.stubs(:sleep)
    end

    describe 'https domain control validation' do
      it 'fails if ca_tag does not match' do
        cname.stubs(:ca_tag).returns('comodoca.com')
        stub_request(:any, cname.dcv_url(true, '', true))
          .to_return(status: 200, body: [cname.csr.sha2_hash, "--#{cname.csr.ca_tag}--", cname.csr.unique_value].join("\n"))
        cname.dcv_verify('https').should be_falsey
      end

      it 'fails if sha2_hash does not match' do
        stub_request(:any, cname.dcv_url(true, '', true))
          .to_return(status: 200, body: ["--#{cname.csr.sha2_hash}--", cname.csr.ca_tag, cname.csr.unique_value].join("\n"))
        cname.dcv_verify('https').should be_falsey
      end

      it 'fails if unique_value does not match' do
        stub_request(:any, cname.dcv_url(true, '', true))
          .to_return(status: 200, body: [cname.csr.sha2_hash, cname.csr.ca_tag, "--#{cname.csr.unique_value}--"].join("\n"))
        cname.dcv_verify('https').should be_falsey
      end
    end

    describe 'cname domain control validation' do
      it 'passes if a record matching cname_destination is found' do
        Resolv::DNS.stubs(:open).returns([Resolv::DNS::Resource::IN::CNAME.new(cname.cname_destination)])
        cname.dcv_verify('cname').should be_truthy
      end

      it 'fails if no record matching cname_destination is found' do
        cname.dcv_verify('cname').should be_falsey
      end
    end

    describe 'http domain control validation' do
      it 'passes if csr values are found' do
        stub_request(:any, cname.dcv_url(false, '', true))
          .to_return(status: 200, body: [cname.csr.sha2_hash, cname.csr.ca_tag, cname.csr.unique_value].join("\n"))
        cname.dcv_verify('http').should be_truthy
      end

      it 'fails if ca_tag does not match' do
        cname.stubs(:ca_tag).returns('comodoca.com')
        stub_request(:any, cname.dcv_url(false, '', true))
          .to_return(status: 200, body: [cname.csr.sha2_hash, "--#{cname.csr.ca_tag}--", cname.csr.unique_value].join("\n"))
        cname.dcv_verify('http').should be_falsey
      end

      it 'fails if sha2_hash does not match' do
        stub_request(:any, cname.dcv_url(false, '', true))
          .to_return(status: 200, body: ["--#{cname.csr.sha2_hash}--", cname.csr.ca_tag, cname.csr.unique_value].join("\n"))
        cname.dcv_verify('http').should be_falsey
      end

      it 'fails if unique_value does not match' do
        stub_request(:any, cname.dcv_url(false, '', true))
          .to_return(status: 200, body: [cname.csr.sha2_hash, cname.csr.ca_tag, "--#{cname.csr.unique_value}--"].join("\n"))
        cname.dcv_verify('http').should be_falsey
      end
    end

    describe 'acme_http domain control validation' do
      let(:ac) { build_stubbed(:api_credential) }

      before do
        logger = mock
        ApiCredential.stubs(:find).returns(ac)
        described_class.any_instance.stubs(:api_credential).returns(ac)
        AcmeManager::HttpVerifier.any_instance.stubs(:thumbprint).returns(ac.acme_acct_pub_key_thumbprint)
        AcmeManager::HttpVerifier.any_instance.stubs(:acme_token).returns(cname.acme_token)
        AcmeManager::HttpVerifier.any_instance.stubs(:logger).returns(logger)
        logger.stubs(:debug).returns(true)
      end

      it 'passes if token and thumbprint are concatenated with .' do
        body = [cname.acme_token, ac.acme_acct_pub_key_thumbprint].join('.')
        AcmeManager::HttpVerifier.any_instance.stubs(:challenge).returns(body)
        cname.dcv_verify('acme_http').should be_truthy
      end

      it 'fails if thumbprint is invalid' do
        body = [cname.acme_token, "--#{ac.acme_acct_pub_key_thumbprint}--"].join('.')
        AcmeManager::HttpVerifier.any_instance.stubs(:challenge).returns(body)
        cname.dcv_verify('acme_http').should be_falsey
      end

      it 'fails if token is invalid' do
        body = ["--#{cname.acme_token}--", ac.acme_acct_pub_key_thumbprint].join('.')
        AcmeManager::HttpVerifier.any_instance.stubs(:challenge).returns(body)
        cname.dcv_verify('acme_http').should be_falsey
      end

      it 'fails if response is not well_formed' do
        body = [cname.acme_token, ac.acme_acct_pub_key_thumbprint, cname.acme_token].join('.')
        AcmeManager::HttpVerifier.any_instance.stubs(:challenge).returns(body)
        cname.dcv_verify('acme_http').should be_falsey
      end
    end

    describe 'acme_dns_txt domain control validation' do
      let(:ac) { build_stubbed(:api_credential) }

      before do
        logger = mock
        ApiCredential.stubs(:find).returns(ac)
        described_class.any_instance.stubs(:api_credential).returns(ac)
        AcmeManager::DnsTxtVerifier.any_instance.stubs(:thumbprint).returns(ac.acme_acct_pub_key_thumbprint)
        AcmeManager::DnsTxtVerifier.any_instance.stubs(:logger).returns(logger)
        logger.stubs(:debug).returns(true)
      end

      it 'passes if thumbprint is present' do
        body = Resolv::DNS::Resource::IN::TXT.new(ac.acme_acct_pub_key_thumbprint)
        AcmeManager::DnsTxtVerifier.any_instance.stubs(:challenge).returns(true)
        AcmeManager::DnsTxtVerifier.any_instance.stubs(:token).returns(body.strings.last)
        cname.dcv_verify('acme_dns_txt').should be_truthy
      end

      it 'fails if thumbprint is invalid' do
        body = Resolv::DNS::Resource::IN::TXT.new("--#{ac.acme_acct_pub_key_thumbprint}--")
        AcmeManager::DnsTxtVerifier.any_instance.stubs(:challenge).returns(true)
        AcmeManager::DnsTxtVerifier.any_instance.stubs(:token).returns(body.strings.last)
        cname.dcv_verify('acme_dns_txt').should be_falsey
      end
    end

    describe 'email domain control validation' do
      it 'fails if when protocol is email' do
        cname.dcv_verify('email').should be_falsey
      end
    end
  end
end
