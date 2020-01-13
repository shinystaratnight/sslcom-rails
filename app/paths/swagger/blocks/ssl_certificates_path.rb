module Swagger
  module Blocks
    class SslCertificatesPath < Path
      swagger_path '/certificates' do
        operation :get do
          key :summary, 'Get a list of purchased SSL certificates'
          key :description, 'List all SSL Certificates'
          key :operation, 'indexCertificates'
          key :produces, %w[application/json]
          key :consumes, %w[application/json]
          key :tags, [
            'certificate'
          ]
          security account_key: []
          security secret_key: []

          parameter :per_page
          parameter :page
          parameter do
            key :name, :start
            key :type, :string
            key :in, :query
            key :description, I18n.t(:start_param_description, scope: :documentation)
          end
          parameter do
            key :name, :end
            key :type, :string
            key :in, :query
            key :description, I18n.t(:end_param_description, scope: :documentation)
          end
          parameter do
            key :name, :filter
            key :type, :string
            key :in, :query
            key :description, I18n.t(:filter_param_description, scope: :documentation)
          end
          parameter do
            key :name, :search
            key :type, :string
            key :in, :query
            key :description, I18n.t(:search_param_description, scope: :documentation)
          end
          parameter do
            key :name, :fields
            key :type, :string
            key :in, :query
            key :description, I18n.t(:fields_param_description, scope: :documentation)
          end
          response 200 do
            key :description, 'Credentials Response'
            schema do
              property :arrayOfObjects do
                key :type, :array
                items do
                  key :type, :object
                  property :ref do
                    key :type, :string
                  end
                  property :description do
                    key :type, :string
                  end
                  property :order_status do
                    key :type, :string
                  end
                  property :order_date do
                    key :type, :string
                  end
                  property :domains_qty_purchased do
                    key :type, :number
                    key :format, :integer
                  end
                  property :wildcard_qty_purchased do
                    key :type, :number
                    key :format, :integer
                  end
                  property :domains do
                    key :type, :arrary
                  end
                end
              end
            end
          end
          response :error do
            key :description, 'Error Response'
            schema do
              key :'$ref', :ErrorResponse
            end
          end
        end
        operation :post do
          key :summary, 'Purchase an SSL Certificate'
          key :description, I18n.t(:create_certificate_description, scope: :documentation)
          key :operation, 'createCertificate'
          key :produces, %w[application/json]
          key :consumes, %w[application/json]
          key :tags, [
            'certificate'
          ]

          security account_key: []
          security secret_key: []

          parameter :product
          parameter :period
          parameter :unique_value
          parameter :csr
          parameter :server_software
          parameter :domains
          parameter :organization
          parameter :organization_unit
          parameter :post_office_box
          parameter :street_address_1
          parameter :street_address_2
          parameter :street_address_3
          parameter :locality
          parameter :state_or_providence
          parameter :country
          parameter :duns_number
          parameter :company_number
          parameter :joi
          parameter :ca_certificate_id
          parameter :external_order_number
          parameter :hide_certificate_reference
          parameter :callback
          parameter :contacts
          parameter :app_rep
          parameter :payment_method
          response 201 do
            key :description, 'Certificate Created Response'
            schema do
              key :'$ref', :CreateCertificateResponse
            end
          end
          response :default do
            key :description, 'Error Response'
            schema do
              key :'$ref', :ErrorResponse
            end
          end
        end
      end

      swagger_path '/certificate/{ref}' do
        operation :get do
          security account_key: []
          security secret_key: []
          key :summary, I18n.t(:certificate_download_summary, scope: :documentation)
          key :description, I18n.t(:certificate_download_description, scope: :documentation)
          key :operation, 'getCertificate'
          key :produces, %w[application/json]
          key :consumes, %w[application/json]
          key :tags, [
            'certificate'
          ]
          parameter :ref
          parameter :response_type
          parameter :response_encoding
          response 200 do
            key :description, 'Certificate Response'
          end
          response :error do
            key :description, 'Error Response'
            schema do
              key :'$ref', :ErrorResponse
            end
          end
        end
        operation :put do
          security account_key: []
          security secret_key: []
          key :summary, I18n.t(:certificate_order_summary, scope: :documentation)
          key :description, I18n.t(:certificate_order_description, scope: :documentation)
          key :operation, 'updateCertificate'
          key :produces, %w[application/json]
          key :consumes, %w[application/json]
          key :tags, [
            'certificate'
          ]
          parameter :ref
          parameter :unique_value
          parameter do
            key :name, :csr
            key :in, :query
            key :type, :string
            key :description, I18n.t(:csr_param_description, scope: :documentation)
            key :required, true
          end
          parameter do
            key :name, :server_software
            key :in, :query
            key :type, :integer
            key :description, I18n.t(:server_software_description, scope: :documentation)
            key :required, true
          end
          parameter :domains
          parameter :organization
          parameter :organization_unit
          parameter :post_office_box
          parameter :state_or_providence
          parameter :street_address_1
          parameter :street_address_2
          parameter :street_address_3
          parameter :postal_code
          parameter :country
          parameter :duns_number
          parameter :company_number
          parameter :joi
          parameter :ca_certificate_id
          parameter :external_order_number
          parameter :hide_certificate_reference
          parameter :callback
          parameter :contacts
          parameter :app_rep
          parameter :payment_method
          response 200 do
            key :description, 'Certificate Response'
            schema do
              key :'$ref', :UpdateCertificateResponse
            end
          end
          response :error do
            key :description, 'Error Response'
            schema do
              key :'$ref', :ErrorResponse
            end
          end
        end

        operation :delete do
          security account_key: []
          security secret_key: []
          key :summary, I18n.t(:certificate_delete_summary, scope: :documentation)
          key :description, I18n.t(:certificate_delete_description, scope: :documentation)
          key :operation, 'deleteCertificate'
          key :produces, %w[application/json]
          key :consumes, %w[application/json]
          key :tags, [
            'certificate'
          ]
          parameter :reason_required
          parameter :serials
          response :error do
            key :description, 'Error Response'
            schema do
              key :'$ref', :ErrorResponse
            end
          end
          response 200 do
            key :description, 'Certificate Revoked'
          end
        end
      end

      swagger_path '/certificate/{ref}/validations/methods' do
        operation :get do
          security account_key: []
          security secret_key: []
          key :summary, I18n.t(:validate_certificate_summary, scope: :documentation)
          key :description, I18n.t(:validate_certificate_description, scope: :documentation)
          key :operation, 'getValidationMethods'
          key :produces, %w[application/json]
          key :consumes, %w[application/json]
          key :tags, [
            'certificate'
          ]
          parameter :ref
          response 200 do
            key :description, 'Validation Methods Response'
          end
          response :error do
            key :description, 'Error Response'
            schema do
              key :'$ref', :ErrorResponse
            end
          end
          # extends SwaggerResponses::GenericError
        end
      end

      swagger_path '/certificates/validations/email' do
        operation :get do
          security account_key: []
          security secret_key: []
          key :summary, I18n.t(:email_validation_options, scope: :documentation)
          key :description, I18n.t(:email_validation_options_description, scope: :documentation)
          key :operation, 'getEmailValidationOptions'
          key :produces, %w[application/json]
          key :consumes, %w[application/json]
          key :tags, [
            'certificate'
          ]
          parameter :domains_required
          response 200 do
            key :description, 'Email Validation Options Response'
          end
          response :error do
            key :description, 'Error Response'
            schema do
              key :'$ref', :ErrorResponse
            end
          end
        end
      end
      swagger_path '/certificates/validations/csr_hash' do
        # this method should probably be a GET
        operation :post do
          security account_key: []
          security secret_key: []
          key :summary, I18n.t(:csr_hash_validation_options, scope: :documentation)
          key :description, I18n.t(:csr_hash_validation_options_description, scope: :documentation)
          key :operation, 'getCSRHashValidationOptions'
          key :produces, %w[application/json]
          key :consumes, %w[application/json]
          key :tags, [
            'certificate'
          ]
          parameter :domains
          parameter :csr_required
          response 200 do
            key :description, 'CSR Hash Validation Options Response'
          end
          response :error do
            key :description, 'Error Response'
            schema do
              key :'$ref', :ErrorResponse
            end
          end
        end
      end
      swagger_path '/certificate/{ref}/api_parameters/{action}' do
        operation :get do
          security account_key: []
          security secret_key: []
          key :summary, I18n.t(:api_parameters, scope: :documentation)
          key :description, I18n.t(:api_parameters_description, scope: :documentation)
          key :operation, 'getApiParameters'
          key :produces, %w[application/json]
          key :consumes, %w[application/json]
          key :tags, [
            'certificate'
          ]
          parameter :ref
          parameter :action_required
          response 200 do
            key :description, 'CSR Hash Validation Options Response'
            schema do
              property :parameters do
                key :type, :object
              end
            end
          end
          response :error do
            key :description, 'Error Response'
            schema do
              key :'$ref', :ErrorResponse
            end
          end
        end
      end
    end
  end
end
