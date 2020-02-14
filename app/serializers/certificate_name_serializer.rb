# frozen_string_literal: true

# == Schema Information
#
# Table name: certificate_names
#
#  id                     :integer          not null, primary key
#  caa_passed             :boolean          default(FALSE)
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
#  index_certificate_names_on_certificate_content_id  (certificate_content_id)
#  index_certificate_names_on_name                    (name)
#  index_certificate_names_on_ssl_account_id          (ssl_account_id)
#

class CertificateNameSerializer < ActiveModel::Serializer
  attribute :name, key: :domain
  attribute :acme_token, key: :http_token
  attribute :acme_token, key: :dns_token
  attribute :validated do
    object.all_domains_validated?
  end
  attribute :validation_source, if: -> { object.all_domains_validated? }
end
