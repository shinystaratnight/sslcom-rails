# frozen_string_literal: true

# == Schema Information
#
# Table name: certificate_names
#
#  id                     :integer          not null, primary key
#  certificate_content_id :integer
#  email                  :string(255)
#  name                   :string(255)
#  is_common_name         :boolean
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  acme_account_id        :string(255)
#  ssl_account_id         :integer
#  caa_passed             :boolean          default(FALSE)
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
