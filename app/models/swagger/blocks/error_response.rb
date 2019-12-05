# frozen_string_literal: true

# app/models/swagger/blocks/error_response.rb
module Swagger
  module Blocks
    class ErrorResponse
      include Swagger::Blocks

      swagger_schema :ErrorResponse do
        key :required, %i[code message]
        property :code do
          key :type, :integer
          key :format, :int32
        end
        property :message do
          key :type, :string
        end
      end
    end
  end
end
