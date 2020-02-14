# frozen_string_literal: true

require 'test_helper'

describe CertificateName do
  subject { CertificateName.new }

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
end
