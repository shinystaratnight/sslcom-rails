# frozen_string_literal: true

# app/models/swagger/blocks/create_certificate_response.rb
module Swagger
  module Blocks
    class UpdateCertificateResponse
      include Swagger::Blocks
      swagger_schema :UpdateCertificateResponse do
        property :ref do
          key :type, :string
        end
        property :registrant do
          key :type, :string
        end
        property :order_status do
          key :type, :string
        end
        property :validations do
          key :type, :object
        end
        property :order_amount do
          key :type, :number
          key :format, :decimal
        end
        property :certificate_url do
          key :type, :string
          key :format, :uri
        end
        property :receipt_url do
          key :type, :string
          key :format, :uri
        end
        property :smart_seal_url do
          key :type, :string
          key :format, :uri
        end
        property :validation_url do
          key :type, :string
          key :format, :uri
        end
        property :certificates do
          key :type, :string
          key :format, :uri
        end
        property :certificate_contents do
          key :type, :object
        end
      end
    end
  end
end
