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

    parameter :create_certificate_parameter do
      key :name, :body
      key :type, :string
      key :in, :body
      key :required, true

      schema do
        property :account_key do
          key :name, :account_key
          key :type, :string
          key :example, 'xxxxxxxxx'
        end
        property :secret_key do
          key :name, :secret_key
          key :type, :string
          key :example, 'xxxxxxxxx'
        end
        property :product do
          key :name, :account_key
          key :type, :number
          key :format, :integer
          key :example, 100
        end
        property :period do
          key :name, :period
          key :type, :number
          key :format, :integer
          key :example, 365
        end
        property :unique_value do
          key :name, :unique_value
          key :type, :string
          key :example, '0cad05061b'
          key :format, :byte
        end
        property :csr do
          key :name, :csr
          key :type, :string
          key :example, I18n.t(:csr_example, scope: :documentation)
        end
        property :server_software do
          key :name, :server_software
          key :type, :integer
          key :example, 13
        end
        property :domains do
          key :name, :domains
          key :type, :object
          key :example, I18n.t(:domains_example, scope: :documentation)
        end
        property :organization do
          key :name, :organization
          key :type, :string
          key :example, I18n.t(:organization_example, scope: :documentation)
        end
        property :organization_unit do
          key :name, :organization_unit
          key :type, :string
          key :example, I18n.t(:organization_unit_example, scope: :documentation)
        end
        property :post_office_box do
          key :name, :post_office_box
          key :type, :object
          key :example, '485'
        end
        property :street_address_1 do
          key :name, :street_address_1
          key :type, :string
          key :example, I18n.t(:street_address_1_example, scope: :documentation)
        end
        property :street_address_2 do
          key :name, :organization_unit
          key :type, :string
          key :example, I18n.t(:street_address_2_example, scope: :documentation)
        end
        property :street_address_3 do
          key :name, :street_address_3
          key :type, :string
          key :example, I18n.t(:street_address_3_example, scope: :documentation)
        end
        property :locality do
          key :name, :locality
          key :type, :string
          key :example, 'Houston'
        end
        property :state_or_providence do
          key :name, :state_or_providence
          key :type, :string
          key :example, 'Texas'
        end
        property :postal_code do
          key :name, :postal_code
          key :type, :string
          key :example, '77098'
        end
        property :country do
          key :name, :country
          key :type, :string
          key :example, 'US'
        end
        property :duns_number do
          key :name, :duns_number
          key :type, :string
          key :example, '15-048-3782'
        end
        property :company_number do
          key :name, :company_number
          key :type, :string
          key :example, '15-048-3782'
        end
        property :joi do
          key :name, :joi
          key :type, :object
          key :example, I18n.t(:joi_example, scope: :documentation)
        end
        property :ca_certificate_id do
          key :name, :ca_certificate_id
          key :type, :number
        end
        property :external_order_number do
          key :name, :external_order_number
          key :type, :string
        end
        property :hide_certificate_reference do
          key :name, :hide_certificate_reference
          key :type, :string
          key :example, 'y'
        end
        property :callback do
          key :name, :callback
          key :type, :object
          key :example, I18n.t(:callback_example, scope: :documentation)
        end
        property :contacts do
          key :name, :contacts
          key :type, :object
          key :example, I18n.t(:contacts_example, scope: :documentation)
        end
        property :app_req do
          key :name, :app_req
          key :type, :object
          key :example, I18n.t(:app_req_example, scope: :documentation)
        end
        property :payment_method do
          key :name, :payment_method
          key :type, :object
          key :example, I18n.t(:payment_method_example, scope: :documentation)
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
