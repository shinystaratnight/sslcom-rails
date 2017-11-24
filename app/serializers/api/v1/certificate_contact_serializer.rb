class Api::V1::CertificateContactSerializer < Api::V1::BaseSerializer
  attribute :title
  attribute :first_name
  attribute :last_name
  attribute :company_name
  attribute :department
  attribute :po_box
  attribute :address1
  attribute :address2
  attribute :address3
  attribute :city
  attribute :state
  attribute :country
  attribute :postal_code
  attribute :email
  attribute :phone
  attribute :ext
  attribute :fax
end
