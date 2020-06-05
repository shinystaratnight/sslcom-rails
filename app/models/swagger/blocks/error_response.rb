module Swagger
  module Blocks
    class ErrorResponse
      include Swagger::Blocks

      swagger_schema :ErrorResponse do
        key :required, %i[errors]
        property :errors do
          key :type, :array
          items do
            key :type, :object
          end
        end
      end
    end
  end
end
