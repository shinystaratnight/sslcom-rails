# frozen_string_literal: true

require 'test_helper'

describe CertificateName do
  subject { create(:certificate_name) }

  context "attributes" do
    should have_db_column :id
    should have_db_column :acme_token
    should have_db_column :caa_passed
    should have_db_column :email
    should have_db_column :is_common_name
    should have_db_column :name
    should have_db_column :created_at
    should have_db_column :updated_at
    should have_db_column :acme_account_id
    should have_db_column :certificate_content_id
    should have_db_column :ssl_account_id
  end

  context "associations" do
    should belong_to :certificate_content
    should have_one :certificate_order
    should have_many    :signed_certificates
    should have_many    :caa_checks
    should have_many    :ca_certificate_requests
    should have_many    :ca_dcv_requests
    should have_many    :ca_dcv_resend_requests
    should have_many    :validated_domain_control_validations
    should have_many    :last_sent_domain_control_validations
    should have_one :domain_control_validation
    should have_many :domain_control_validations
  end

  context 'ACME support' do
    describe '.generate_acme_token' do
      it 'is 128 characters long' do
        subject.generate_acme_token
        assert_equal(128, subject.acme_token.length)
      end
      it 'does not have = padding' do
        subject.generate_acme_token
        assert_no_match(/=$/, subject.acme_token)
      end
      it 'is url safe' do
        subject.generate_acme_token
        assert_match(/^[a-zA-Z0-9_-]*$/, subject.acme_token)
      end
    end
  end

  context 'domain control validation' do
    describe 'https domain validation' do
      it 'passes if csr values are found' do
        host = subject.name
        subject.domain_control_validation = DomainControlValidation.create(dcv_method: 'https', candidate_addresses: host, csr_id: subject.csr.id)
        subject.save
        stub_request(:any, subject.dcv_url(true, '', true))
          .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
          .to_return(status: 200, body: [subject.csr.sha2_hash, subject.csr.ca_tag, subject.csr.unique_value].join("\n"))
        assert_equal(true, subject.dcv_verify)
      end

      it 'fails if ca_tag does not match' do
        host = subject.name
        subject.domain_control_validation = DomainControlValidation.create(dcv_method: 'https', candidate_addresses: host, csr_id: subject.csr.id)
        subject.save
        stub_request(:any, subject.dcv_url(true, '', true))
          .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
          .to_return(status: 200, body: [subject.csr.sha2_hash, "--#{subject.csr.ca_tag}--", subject.csr.unique_value].join("\n"))
        assert_equal(nil, subject.dcv_verify)
      end

      it 'fails if sha2_hash does not match' do
        host = subject.name
        subject.domain_control_validation = DomainControlValidation.create(dcv_method: 'https', candidate_addresses: host, csr_id: subject.csr.id)
        subject.save
        stub_request(:any, subject.dcv_url(true, '', true))
          .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
          .to_return(status: 200, body: ["--#{subject.csr.sha2_hash}--", subject.csr.ca_tag, subject.csr.unique_value].join("\n"))
        assert_equal(nil, subject.dcv_verify)
      end

      it 'fails if unique_value does not match' do
        host = subject.name
        subject.domain_control_validation = DomainControlValidation.create(dcv_method: 'https', candidate_addresses: host, csr_id: subject.csr.id)
        subject.save
        stub_request(:any, subject.dcv_url(true, '', true))
          .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
          .to_return(status: 200, body: [subject.csr.sha2_hash, subject.csr.ca_tag, "--#{subject.csr.unique_value}--"].join("\n"))
        assert_equal(nil, subject.dcv_verify)
      end
    end
  describe 'cname domain control validation'
    it 'fails if ca_tag does not match' do
      stub_request(:any, subject.dcv_url(true, '', true))
        .to_return(status: 200, body: [subject.csr.sha2_hash, "--#{subject.csr.ca_tag}--", subject.csr.unique_value].join("\n"))
      assert_equal(nil, subject.dcv_verify)
    end

    it 'fails if sha2_hash does not match' do
      stub_request(:any, subject.dcv_url(true, '', true))
        .to_return(status: 200, body: ["--#{subject.csr.sha2_hash}--", subject.csr.ca_tag, subject.csr.unique_value].join("\n"))
      assert_equal(nil, subject.dcv_verify)
    end

    it 'fails if unique_value does not match' do
      stub_request(:any, subject.dcv_url(true, '', true))
        .to_return(status: 200, body: [subject.csr.sha2_hash, subject.csr.ca_tag, "--#{subject.csr.unique_value}--"].join("\n"))
      assert_equal(nil, subject.dcv_verify)
    end

    describe 'https domain control validation' do
      before do
        host = subject.name
        subject.domain_control_validation = DomainControlValidation.create(dcv_method: 'https', candidate_addresses: host, csr_id: subject.csr.id)
        subject.save
      end

      it 'passes if csr values are found' do
        stub_request(:any, subject.dcv_url(true, '', true))
          .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
          .to_return(status: 200, body: [subject.csr.sha2_hash, subject.csr.ca_tag, subject.csr.unique_value].join("\n"))
        assert_equal(true, subject.dcv_verify)
      end

      it 'fails if ca_tag does not match' do
        stub_request(:any, subject.dcv_url(true, '', true))
          .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
          .to_return(status: 200, body: [subject.csr.sha2_hash, "--#{subject.csr.ca_tag}--", subject.csr.unique_value].join("\n"))
        assert_equal(nil, subject.dcv_verify)
      end

      it 'fails if sha2_hash does not match' do
        stub_request(:any, subject.dcv_url(true, '', true))
          .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
          .to_return(status: 200, body: ["--#{subject.csr.sha2_hash}--", subject.csr.ca_tag, subject.csr.unique_value].join("\n"))
        assert_equal(nil, subject.dcv_verify)
      end

      it 'fails if unique_value does not match' do
        stub_request(:any, subject.dcv_url(true, '', true))
          .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
          .to_return(status: 200, body: [subject.csr.sha2_hash, subject.csr.ca_tag, "--#{subject.csr.unique_value}--"].join("\n"))
        assert_equal(nil, subject.dcv_verify)
      end
  end
  describe 'cname domain control validation' do
    before do
      host = subject.name
      subject.domain_control_validation = DomainControlValidation.create(dcv_method: 'cname', candidate_addresses: host, csr_id: subject.csr.id)
      subject.save
    end

    it 'passes if a record matching cname_destination is found' do
      Resolv::DNS.any_instance.stubs(:getresources).returns([Resolv::DNS::Resource::IN::CNAME.new(subject.cname_destination)])
      assert_equal(true, subject.dcv_verify)
    end

    it 'fails if no record matching cname_destination is found' do
      Resolv::DNS.any_instance.stubs(:getresources).returns([])
      assert_equal(false, subject.dcv_verify)
    end
  end
end
