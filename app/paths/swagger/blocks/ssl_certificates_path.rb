module Swagger
  module Blocks
    class SslCertificatesPath < Path
      swagger_path '/certificates' do
        operation :get do
          key :summary, 'SSL Certificates Collection'
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
          response :default do
            key :description, 'Error Response'
            schema do
              key :'$ref', :ErrorResponse
            end
          end
        end
        operation :post do
          key :summary, 'Create an SSL Certificate'
          key :description, I18n.t(:create_certificate_description, scope: :documentation)
          key :operation, 'createCertificate'
          key :produces, %w[application/json]
          key :consumes, %w[application/json]
          key :tags, [
            'certificate'
          ]

          security account_key: []
          security secret_key: []

          parameter do
            key :name, :product
            key :in, :query
            key :type, :number
            key :format, :integer
            key :required, true
            key :description, I18n.t(:product_param_description, scope: :documentation)
            key :example, 100
          end
          parameter do
            key :name, :period
            key :in, :query
            key :type, :number
            key :format, :integer
            key :required, true
            key :description, I18n.t(:period_param_description, scope: :documentation)
          end
          parameter do
            key :name, :unique_value
            key :in, :query
            key :type, :string
            key :format, :byte
            key :description, I18n.t(:unique_value_param_description, scope: :documentation)
          end
          parameter do
            key :name, :csr
            key :in, :query
            key :type, :string
            key :description, I18n.t(:csr_param_description, scope: :documentation)
          end
          parameter do
            key :name, :server_software
            key :in, :query
            key :type, :integer
            key :description, I18n.t(:server_software_description, scope: :documentation)
          end
          parameter do
            key :name, :domains
            key :in, :query
            key :type, :object
            key :description, I18n.t(:domains_param_description, scope: :documentation)
          end
          parameter do
            key :name, :organization
            key :in, :query
            key :type, :string
            key :description, I18n.t(:organization_param_description, scope: :documentation)
            key :required, true
          end
          parameter do
            key :name, :organization_unit
            key :in, :query
            key :type, :string
            key :description, I18n.t(:organization_unit_param_description, scope: :documentation)
          end
          parameter do
            key :name, :post_office_box
            key :in, :query
            key :type, :string
            key :description, I18n.t(:post_office_box_param_description, scope: :documentation)
          end
          parameter do
            key :name, :street_address_1
            key :in, :query
            key :type, :string
            key :description, I18n.t(:street_address_1_param_description, scope: :documentation)
            key :required, true
          end
          parameter do
            key :name, :organization_unit
            key :in, :query
            key :type, :string
            key :description, I18n.t(:street_address_2_param_description, scope: :documentation)
          end
          parameter do
            key :name, :street_address_3
            key :in, :query
            key :type, :string
            key :description, I18n.t(:street_address_3_param_description, scope: :documentation)
          end
          parameter do
            key :name, :locality
            key :in, :query
            key :type, :string
            key :description, I18n.t(:locality_param_description, scope: :documentation)
          end
          parameter do
            key :name, :state_or_providence
            key :in, :query
            key :type, :string
            key :description, I18n.t(:state_or_providence_param_description, scope: :documentation)
            key :required, true
          end
          parameter do
            key :name, :state_or_providence
            key :in, :query
            key :type, :string
            key :description, I18n.t(:state_or_providence_param_description, scope: :documentation)
            key :required, true
          end
          parameter do
            key :name, :country
            key :in, :query
            key :type, :string
            key :description, I18n.t(:country_param_description, scope: :documentation)
            key :required, true
          end
          parameter do
            key :name, :duns_number
            key :in, :query
            key :type, :string
            key :description, I18n.t(:duns_number_param_description, scope: :documentation)
          end
          parameter do
            key :name, :company_number
            key :in, :query
            key :type, :string
            key :description, I18n.t(:company_number_params_description, scope: :documentation)
          end
          parameter do
            key :name, :joi
            key :in, :query
            key :type, :object
            key :description, I18n.t(:joi_param_description, scope: :documentation)
          end
          parameter do
            key :name, :ca_certificate_id
            key :in, :query
            key :description, I18n.t(:ca_certificate_id_param_description, scope: :documentation)
          end
          parameter do
            key :name, :external_order_number
            key :in, :query
            key :description, I18n.t(:external_order_number_param_description, scope: :documentation)
          end
          parameter do
            key :name, :hide_certificate_reference
            key :in, :query
            key :type, :string
            key :description, I18n.t(:hide_certificate_reference_description, scope: :documentation)
          end
          parameter do
            key :name, :callback
            key :in, :query
            key :type, :object
            key :description, I18n.t(:callback_param_description, scope: :documentation)
          end
          parameter do
            key :name, :contacts
            key :in, :query
            key :type, :object
            key :description, I18n.t(:contacts_param_description, scope: :documentation)
            key :required, true
          end
          parameter do
            key :name, :app_req
            key :in, :query
            key :type, :object
            key :description, I18n.t(:app_req_param_description, scope: :documentation)
          end
          parameter do
            key :name, :payment_method
            key :in, :query
            key :type, :object
            key :description, I18n.t(:payment_method_param_description, scope: :documentation)
          end
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
    end
  end
end
