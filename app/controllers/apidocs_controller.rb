# frozen_string_literal: true

# app/controllers/apidocs_controller.rb
class ApidocsController < ActionController::Base
  include Swagger::Blocks

  swagger_root do
    key :swagger, '2.0'
    info do
      key :version, '1.0.0'
      key :title, 'SSL.com Developer API'
      key :description, 'demonstrates features in the SSL.com API'
      #   key :termsOfService, 'http://helloreverb.com/terms/'
      contact do
        key :name, 'SSL.com API Team'
      end
      license do
        key :name, 'MIT'
      end
    end

    parameter :create_user_parameter do
      key :name, :body
      key :type, :string
      key :in, :body
      key :description, 'User account information'
      key :required, true

      schema do
        property :login do
          key :name, :login
          key :type, :string
          key :in, :body
          key :description, 'login used when signing in'
          key :required, true
          key :example, 'swaggeruser'
        end
        property :email do
          key :name, :email
          key :type, :string
          key :in, :body
          key :description, 'email address associated with the new user'
          key :required, true
          key :format, :email
          key :example, 'user@gmail.com'
        end
        property :password do
          key :name, :password
          key :format, :password
          key :type, :string
          key :in, :body
          key :description, 'password the user signs in with'
          key :required, true
          key :example, '@Sup3AwE$0We'
        end
      end
    end

    tag do
      key :name, 'user'
      key :description, 'User operations'
      externalDocs do
        key :description, 'Find more info here'
        key :url, 'https://swagger.io'
      end
    end
    key :host, 'sws.sslpki.local:3000'
    key :basePath, '/'
    key :consumes, ['application/json']
    key :produces, ['application/json']
  end

  # A list of all classes that have swagger_* declarations.
  SWAGGERED_CLASSES = [
    Api::V1::ApiUserRequestsController,
    User,
    Swagger::Blocks::ErrorResponse,
    Swagger::Blocks::CredentialsResponse,
    self
  ].freeze

  def index
    render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
  end
end
