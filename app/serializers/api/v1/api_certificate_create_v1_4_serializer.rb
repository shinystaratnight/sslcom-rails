class Api::V1::ApiCertificateCreate_v1_4Serializer < Api::V1::BaseSerializer
  
  attribute :ref
  attribute :registrant
  attribute :order_status
  attribute :validations
  attribute :order_amount
  attribute :certificate_url
  attribute :receipt_url
  attribute :smart_seal_url
  attribute :validation_url
  attribute :api_request
  attribute :api_response
  attribute :debug
  
  def attributes
    attrs = super
    if object.debug.nil?
      attrs = attrs.delete_if {|key, value| %w{api-request api-response debug}.include?(key)}
    end
    attrs
  end
end
