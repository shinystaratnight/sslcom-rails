class ApiUserShow_v1_4 < ApiUserRequest
  attr_accessor :user_url, :api_request, :api_response, :error_code, :error_message, :status, :available_funds

  validates :login, :password, presence: true
  validates :password, length: { in: 6..20 }
end
