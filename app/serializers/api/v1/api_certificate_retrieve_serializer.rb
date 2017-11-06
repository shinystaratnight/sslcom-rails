class Api::V1::ApiCertificateRetrieveSerializer < Api::V1::BaseSerializer
  attribute :ref
  attribute :description
  attribute :order_status
  attribute :order_date
  attribute :expiration_date
  attribute :domains
  attribute :common_name
  attribute :product_type
  attribute :period
end
