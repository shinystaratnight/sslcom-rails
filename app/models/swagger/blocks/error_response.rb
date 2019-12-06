# frozen_string_literal: true

# app/models/swagger/blocks/error_response.rb
module Swagger
  module Blocks
    class ErrorResponse
      include Swagger::Blocks

      swagger_schema :ErrorResponse do
        key :required, %i[errors]
        property :errors do
          key :type, :array
          items do
            key :type, :string
          end
        end
      end
    end
  end
end
