# == Schema Information
#
# Table name: ca_api_requests
#
#  id                   :integer          not null, primary key
#  api_requestable_type :string(191)
#  ca                   :string(255)
#  certificate_chain    :text(65535)
#  method               :string(255)
#  parameters           :text(65535)
#  raw_request          :text(65535)
#  request_method       :text(65535)
#  request_url          :text(65535)
#  response             :text(16777215)
#  type                 :string(191)
#  username             :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#  api_requestable_id   :integer
#  approval_id          :string(255)
#
# Indexes
#
#  index_ca_api_requests_on_api_requestable                          (api_requestable_id,api_requestable_type)
#  index_ca_api_requests_on_approval_id                              (approval_id)
#  index_ca_api_requests_on_id_and_type                              (id,type)
#  index_ca_api_requests_on_type_and_api_requestable                 (id,api_requestable_id,api_requestable_type,type) UNIQUE
#  index_ca_api_requests_on_type_and_api_requestable_and_created_at  (id,api_requestable_id,api_requestable_type,type,created_at)
#  index_ca_api_requests_on_type_and_username                        (type,username)
#  index_ca_api_requests_on_username_and_approval_id                 (username,approval_id) UNIQUE
#

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
      @user.create_ssl_account([Role.get_owner_id])
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
