class CertificateNameSerializer < ActiveModel::Serializer
  attribute :domain
  attribute :http_token
  attribute :dns_token
  attribute :validated do
    object.validated?
  end
  attribute :validation_method, key: :validation_source
  attribute :status
end
