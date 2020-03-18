# frozen_string_literal: true

# == Schema Information
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

describe Domain do
  context 'inherited from CertificateName' do
    describe 'scopes' do
      it 'inherits search_domains' do
        expect(proc { described_class.search_domains('ssl') }).not_to raise_error
      end
      it 'inherits expired_validation' do
        expect(proc { described_class.expired_validation }).not_to raise_error
      end
    end
  end
end