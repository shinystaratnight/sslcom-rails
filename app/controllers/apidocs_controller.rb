# frozen_string_literal: true

# app/controllers/apidocs_controller.rb
class ApidocsController < ApplicationController
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

    tag do
      key :name, 'user'
      key :description, 'User operations'
      externalDocs do
        key :description, 'Find more info here'
        key :url, 'https://swagger.io'
      end
    end
    tag do
      key :name, 'certificate'
      key :description, I18n.t(:certificate_tag_description, scope: :documentation)
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
    Swagger::Blocks::CreateCertificateResponse,
    Api::V1::ApiCertificateRequestsController,
    self
  ].freeze

  def index
    render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
  end
end
