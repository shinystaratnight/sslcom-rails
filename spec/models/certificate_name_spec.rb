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
  before :each do
    stub_roles
    stub_triggers
    stub_server_software
  end

  context 'attributes' do
    it { should have_db_column :id }
    it { should have_db_column :acme_token }
    it { should have_db_column :caa_passed }
    it { should have_db_column :email }
    it { should have_db_column :is_common_name }
    it { should have_db_column :name }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :acme_account_id }
    it { should have_db_column :certificate_content_id }
    it { should have_db_column :ssl_account_id }
  end

  context 'associations' do
    it { should belong_to :certificate_content }
    it { should have_one :certificate_order }
    it { should have_many    :signed_certificates }
    it { should have_many    :caa_checks }
    it { should have_many    :ca_certificate_requests }
    it { should have_many    :ca_dcv_requests }
    it { should have_many    :ca_dcv_resend_requests }
    it { should have_many    :validated_domain_control_validations }
    it { should have_many    :last_sent_domain_control_validations }
    it { should have_one :domain_control_validation }
    it { should have_many :domain_control_validations }
  end

  context 'ACME support' do
    describe '.generate_acme_token' do
      let!(:certificate_name){ build(:certificate_name) }
      before(:each) do
        CertificateName.stubs(:exists?).returns(false)
      end
      it 'is 128 characters long' do
        certificate_name.generate_acme_token
        assert_equal(128, certificate_name.acme_token.length)
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
  end

  context 'domain control validation' do
    let!(:cname) { build_stubbed(:certificate_name) }
    before :each do
      cname.stubs(:fail_dcv).returns(false)
      cname.stubs(:satify_dcv).returns(true)
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
      before(:each) do
        logger = mock
        ApiCredential.stubs(:find).returns(ac)
        CertificateName.any_instance.stubs(:api_credential).returns(ac)
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
      before(:each) do
        logger = mock
        ApiCredential.stubs(:find).returns(ac)
        CertificateName.any_instance.stubs(:api_credential).returns(ac)
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