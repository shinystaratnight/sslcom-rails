# frozen_string_literal: true

require 'test_helper'

describe Domain do
  context 'inherited from CertificateName' do
    describe 'scopes' do
      it 'inherits search_domains' do
        proc { Domain.search_domains('ssl') }.must_be_silent
      end
      it 'inherits expired_validation' do
        proc { Domain.expired_validation }.must_be_silent
      end
    end
  end
end
