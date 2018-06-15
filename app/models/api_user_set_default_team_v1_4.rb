class ApiUserSetDefaultTeam_v1_4 < ApiUserRequest
  attr_accessor :api_request, :api_response, :error_code, :error_message, :success_message, :acct_number

  validates :login, :password, presence: true

end
