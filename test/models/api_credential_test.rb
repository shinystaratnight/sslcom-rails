# frozen_string_literal: true

require 'test_helper'

describe ApiCredential do
  subject { ApiCredential.new }

  context 'ACME support' do
    describe '.acme_acct_pub_key_thumbprint' do
      it 'is 60 characters long' do
        assert_equal(60, subject.acme_acct_pub_key_thumbprint.length)
      end
    end
  end
end
