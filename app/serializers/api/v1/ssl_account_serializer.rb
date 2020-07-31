class Api::V1::SslAccountSerializer < Api::V1::BaseSerializer
  attribute  :acct_number
  attribute  :billing_method
  attribute  :company_name
  attribute  :duo_enabled
  attribute  :duo_own_used
  attribute  :epki_agreement
  attribute  :issue_dv_no_validation
  attribute  :no_limit
  attribute  :roles
  attribute  :sec_type
  attribute  :ssl_slug
  attribute  :status
  attribute  :workflow_state
  attribute  :created_at
  attribute  :updated_at
  attribute  :default_folder_id
end
