# frozen_string_literal: true

# app/models/swagger/blocks/user_info_response.rb
module Swagger
  module Blocks
    class UserInfoResponse
      include Swagger::Blocks

      swagger_schema :UserInfoResponse do
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
