module Swagger
  module Blocks
    class CredentialsResponse
      include Swagger::Blocks

      swagger_schema :CredentialsResponse do
        property :login do
          key :type, :string
        end
        property :email do
          key :type, :string
          key :format, :email
        end
        property :account_number do
          key :type, :string
        end
        property :account_key do
          key :type, :string
        end
        property :secret_key do
          key :type, :string
        end
        property :status do
          key :type, :string
        end
        property :user_url do
          key :type, :string
          key :format, :uri
        end
        property :avialable_funds do
          key :type, :number
          key :format, :float
        end
      end
    end
  end
end
