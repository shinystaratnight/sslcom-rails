require "declarative_authorization/maintenance"

class ApiUserCreate_v1_4 < ApiUserRequest
  attr_accessor :user_url, :api_request, :api_response, :error_code, :error_message, :status

  validates :login, :email, :password, presence: true
  validates :email, email: true
  validates :password, length: { in: 6..20 }

  def create_user
    params={login: self.login, email: self.email, password: self.password,password_confirmation: self.password}
    @user = User.create(params)
    if @user.errors.empty?
      @user.create_ssl_account
      @user.roles << Role.find_by_name(Role::CUSTOMER)
      @user.signup!({user: params})
      @user.activate!({user: params})
      @user.deliver_activation_confirmation!
      @user_session = UserSession.create(@user)
      @current_user_session = @user_session
      Authorization.current_user = @current_user = @user_session.record
    end
    @user
  end
end
