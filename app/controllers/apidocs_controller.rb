# frozen_string_literal: true

# app/controllers/apidocs_controller.rb
class ApidocsController < ApplicationController
  include Swagger::Blocks

  swagger_root do
    key :swagger, '2.0'
    info do
      key :version, '1.0.0'
      key :title, I18n.t(:title, scope: :documentation)
      key :description, I18n.t(:introduction, scope: :documentation)
      #   key :termsOfService, 'http://helloreverb.com/terms/'
      contact do
        key :name, 'SSL.com API Team'
      end
      license do
        key :name, 'MIT'
      end
    end
    security_definition :account_key, type: :apiKey do
      key :name, :account_key
      key :in, :query
    end
    security_definition :secret_key, type: :apiKey do
      key :name, :secret_key
      key :in, :query
    end

    parameter :per_page do
      key :name, :per_page
      key :in, :query
      key :description, 'The number of records per page (default is 10 if unspecified).'
    end
    parameter :page do
      key :name, :page
      key :in, :query
      key :description, 'The page number. Example: if per_page is set to 10, and page is 5, then records 51-60 will be returned.'
    end

    tag do
      key :name, 'user'
      key :description, 'User Operations'
      externalDocs do
        key :description, 'Find more info here'
        key :url, 'https://www.ssl.com/guide/ssl-coms-sws-api-introduction/'
      end
    end
    tag do
      key :name, 'certificate'
      key :description, I18n.t(:certificate_tag_description, scope: :documentation)
      externalDocs do
        key :description, 'Find more info here'
        key :url, 'https://www.ssl.com/guide/ssl-coms-sws-api-introduction/'
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
    Swagger::Blocks::CreateCertificateResponse,
    Api::V1::ApiCertificateRequestsController,
    Swagger::Blocks::SslCertificatesPath,
    self
  ].freeze

  def index
    render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
  end
end
