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
    parameter :product do
      key :name, :product
      key :in, :query
      key :type, :number
      key :format, :integer
      key :required, true
      key :description, I18n.t(:product_param_description, scope: :documentation)
      key :example, 100
    end
    parameter :period do
      key :name, :period
      key :in, :query
      key :type, :number
      key :format, :integer
      key :required, true
      key :description, I18n.t(:period_param_description, scope: :documentation)
    end
    parameter :unique_value do
      key :name, :unique_value
      key :in, :query
      key :type, :string
      key :format, :byte
      key :description, I18n.t(:unique_value_param_description, scope: :documentation)
    end
    parameter :csr do
      key :name, :csr
      key :in, :query
      key :type, :string
      key :description, I18n.t(:csr_param_description, scope: :documentation)
    end
    parameter :csr_required do
      key :name, :csr
      key :in, :query
      key :type, :string
      key :required, true
      key :description, I18n.t(:csr_param_description, scope: :documentation)
    end
    parameter :server_software do
      key :name, :server_software
      key :in, :query
      key :type, :integer
      key :description, I18n.t(:server_software_description, scope: :documentation)
    end
    parameter :domains do
      key :name, :domains
      key :in, :query
      key :type, :object
      key :description, I18n.t(:domains_param_description, scope: :documentation)
    end
    parameter :domains_required do
      key :name, 'domains[]='
      key :in, :query
      key :type, :string
      key :required, true
      key :description, I18n.t(:validation_domains_param_description, scope: :documentation)
    end
    parameter :organization do
      key :name, :organization
      key :in, :query
      key :type, :string
      key :description, I18n.t(:organization_param_description, scope: :documentation)
      key :required, true
    end
    parameter :organization_unit do
      key :name, :organization_unit
      key :in, :query
      key :type, :string
      key :description, I18n.t(:organization_unit_param_description, scope: :documentation)
    end
    parameter :post_office_box do
      key :name, :post_office_box
      key :in, :query
      key :type, :string
      key :description, I18n.t(:post_office_box_param_description, scope: :documentation)
    end
    parameter :street_address_1 do
      key :name, :street_address_1
      key :in, :query
      key :type, :string
      key :description, I18n.t(:street_address_1_param_description, scope: :documentation)
      key :required, true
    end
    parameter :street_address_2 do
      key :name, :street_address_2
      key :in, :query
      key :type, :string
      key :description, I18n.t(:street_address_2_param_description, scope: :documentation)
    end
    parameter :street_address_3 do
      key :name, :street_address_3
      key :in, :query
      key :type, :string
      key :description, I18n.t(:street_address_3_param_description, scope: :documentation)
    end
    parameter :locality do
      key :name, :locality
      key :in, :query
      key :type, :string
      key :description, I18n.t(:locality_param_description, scope: :documentation)
    end
    parameter :state_or_providence do
      key :name, :state_or_providence
      key :in, :query
      key :type, :string
      key :description, I18n.t(:state_or_providence_param_description, scope: :documentation)
      key :required, true
    end
    parameter :postal_code do
      key :name, :postal_code
      key :in, :query
      key :type, :string
      key :description, I18n.t(:postal_code_param_description, scope: :documentation)
      key :required, true
    end
    parameter :country do
      key :name, :country
      key :in, :query
      key :type, :string
      key :description, I18n.t(:country_param_description, scope: :documentation)
      key :required, true
    end
    parameter :duns_number do
      key :name, :duns_number
      key :in, :query
      key :type, :string
      key :description, I18n.t(:duns_number_param_description, scope: :documentation)
    end
    parameter :company_number do
      key :name, :company_number
      key :in, :query
      key :type, :string
      key :description, I18n.t(:company_number_params_description, scope: :documentation)
    end
    parameter :joi do
      key :name, :joi
      key :in, :query
      key :type, :object
      key :description, I18n.t(:joi_param_description, scope: :documentation)
    end
    parameter :ca_certificate_id do
      key :name, :ca_certificate_id
      key :in, :query
      key :description, I18n.t(:ca_certificate_id_param_description, scope: :documentation)
    end
    parameter :external_order_number do
      key :name, :external_order_number
      key :in, :query
      key :description, I18n.t(:external_order_number_param_description, scope: :documentation)
    end
    parameter :hide_certificate_reference do
      key :name, :hide_certificate_reference
      key :in, :query
      key :type, :string
      key :description, I18n.t(:hide_certificate_reference_description, scope: :documentation)
    end
    parameter :callback do
      key :name, :callback
      key :in, :query
      key :type, :object
      key :description, I18n.t(:callback_param_description, scope: :documentation)
    end
    parameter :contacts do
      key :name, :contacts
      key :in, :query
      key :type, :object
      key :description, I18n.t(:contacts_param_description, scope: :documentation)
      key :required, true
    end
    parameter :app_rep do
      key :name, :app_rep
      key :in, :query
      key :type, :object
      key :description, I18n.t(:app_req_param_description, scope: :documentation)
    end
    parameter :payment_method do
      key :name, :payment_method
      key :in, :query
      key :type, :object
      key :description, I18n.t(:payment_method_param_description, scope: :documentation)
    end
    parameter :response_type do
      key :name, :response_type
      key :in, :query
      key :type, :string
      key :description, I18n.t(:response_type_param_description, scope: :documentation)
    end
    parameter :response_encoding do
      key :name, :response_encoding
      key :in, :query
      key :type, :string
      key :description, I18n.t(:response_encoding_param_description, scope: :documentation)
    end
    parameter :ref do
      key :name, :ref
      key :in, :path
      key :type, :string
      key :description, I18n.t(:ref_param_description, scope: :documentation)
      key :required, true
    end
    parameter :reason_required do
      key :name, :reason
      key :in, :query
      key :type, :string
      key :description, I18n.t(:reason_param_description, scope: :documentation)
      key :required, true
    end
    parameter :serials do
      key :name, :serials
      key :in, :query
      key :type, :string
      key :description, I18n.t(:serials_param_description, scope: :documentation)
    end
    parameter :action_required do
      key :name, :action
      key :in, :path
      key :type, :string
      key :description, I18n.t(:action_param_description, scope: :documentation)
      key :required, true
    end
    tag do
      key :name, 'user'
      key :description, 'User Operations'
      externalDocs do
        key :description, 'Find more info here'
        key :url, 'https://www.ssl.com/guide/ssl-coms-sws-api-introduction#access'
      end
    end
    tag do
      key :name, 'certificate'
      key :description, I18n.t(:certificate_tag_description, scope: :documentation)
      externalDocs do
        key :description, 'Find more info here'
        key :url, 'https://www.ssl.com/guide/ssl-coms-sws-api-introduction/#issue'
      end
    end
    key :host, 'sws.sslpki.local:3000'
    key :basePath, '/'
    key :consumes, ['application/json']
    key :produces, ['application/json']
  end

  # A list of all classes that have swagger_* declarations.
  SWAGGERED_CLASSES = [
    Swagger::Blocks::SslCertificatesPath,
    Api::V1::ApiUserRequestsController,
    User,
    Swagger::Blocks::ErrorResponse,
    Swagger::Blocks::CredentialsResponse,
    Swagger::Blocks::CreateCertificateResponse,
    Swagger::Blocks::UpdateCertificateResponse,
    # Api::V1::ApiCertificateRequestsController,
    self
  ].freeze

  def index
    render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
  end
end
