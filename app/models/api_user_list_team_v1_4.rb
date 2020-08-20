class ApiUserListTeam_v1_4 < ApiUserRequest
  attr_accessor :acct_number, :api_request, :api_response, :error_code, :error_message, :company_name, :roles, :created_at, :updated_at, :status, :ssl_slug, :issue_dv_no_validation, :billing_method,:available_funds, :currency, :reseller_tier, :is_default_team

  validates :login, :password, presence: true
  validates :company_name, length: {in: 2..20}, allow_nil: true

end
