require "declarative_authorization/maintenance"

class ApiUserCreate_v1_4 < ApiUserRequest
  attr_accessor :user_url, :api_request, :api_response, :error_code, :error_message, :status

  validates :login, :email, :password, presence: true
  validates :email, email: true
  validates :password, length: { in: 6..20 }

  def create_user
    params = {
      login: self.login,
      email: self.email,
      password: self.password,
      password_confirmation: self.password,
      persist_notice: true
    }
    @user = User.create(params)
    if @user.errors.empty?
      @user.signup!({user: params})
      @user.activate!({user: params})

      # Check Code Signing Certificate Order for assign as assignee.
      CertificateOrder.unscoped.search_validated_not_assigned(@user.email).each do |cert_order|
        cert_order.update_attribute(:assignee, @user)
        LockedRecipient.create_for_co(cert_order)
      end

      @user.deliver_activation_confirmation!
      @user_session = UserSession.create(@user)
      @current_user_session = @user_session
      Authorization.current_user = @current_user = @user_session.record
    end
    @user
  end
end
