# frozen_string_literal: true

require 'test_helper'

describe CertificateName do
  subject { CertificateName.new }

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
