# frozen_string_literal: true

class U2fsController < ApplicationController
  before_action :current_user
  before_action :require_user, except: %i[new verify]
  skip_before_action :use_2fa_authentication
  skip_before_action :verify_u2f_authentication, only: %i[new verify]

  def index
    @u2fs = current_user.u2fs
    key_handles = current_user.u2fs.pluck(:key_handle)

    # Prepare what we need to add a new key to user account
    @app_id = u2f.app_id
    @registration_requests = u2f.registration_requests
    @sign_requests = u2f.authentication_requests(key_handles)
    # Store challenges. We need them for the verification step
    session[:challenges] = @registration_requests.map(&:challenge)

    redirect_to verifications_path unless current_user.authy_user && current_user.phone && current_user.phone_prefix
  end

  def new
    redirect_to user_account_path if session[:authenticated]
    @u2f_info = {}
    key_handles = current_user.u2fs.pluck(:key_handle)

    u2f = U2F::U2F.new(request.base_url)
    unless key_handles.empty?
      # Generate SignRequests
      @app_id = u2f.app_id
      @sign_requests = u2f.authentication_requests(key_handles)

      session[:challenge] = u2f.challenge
    end
    session[:u2f_failed_count] ||= 0
  end

  def verify
    @user ||= current_user || User.find_by(id: session[:pre_authenticated_user_id])
    redirect_to login_path and return unless @user

    # No need for verification if user does not have any keys
    return true unless @user.u2fs.any?

    # If user has keys, we need to have a u2f_response, so that we can validate it!
    return false if params['u2f_response'].blank?

    if params[:error_message].present? || JSON.parse(params[:u2f_response])['errorCode'].present?
      flash[:error] = params[:error_message]
      session[:u2f_failed_count] += 1
      u2f_timeout = true if JSON.parse(params[:u2f_response])['errorCode'] == 5

      redirect_to logout_path and return if u2f_timeout || session[:u2f_failed_count] >= 3
      redirect_to new_u2f_path and return
    end

    @result_obj = params[:result_object]
    response = U2F::SignResponse.load_from_json(params[:u2f_response]) if params[:u2f_response].present?
    u2f_registration = @user.u2fs.find_by(key_handle: response.key_handle) if response&.key_handle

    begin
      u2f.authenticate!(
        session[:challenge],
        response,
        Base64.decode64(u2f_registration.public_key),
        u2f_registration.counter
      )

      u2f_registration.update(counter: response.counter)

      session[:authenticated] = true
      respond_to do |format|
        format.html {
          # Check if user has verifications
          if  current_user.authy_user && current_user.phone && current_user.phone_prefix
            set_redirect(user: @user)
          else
            redirect_to verifications_path and return
          end
        }
      end
    rescue U2F::Error => e
      flash[:error] = 'Unable to authenticate with U2F: ' + e.class.name # unless params[:user]
      session[:u2f_failed_count] += 1

      redirect_to new_u2f_path
    ensure
      session.delete(:challenge)
    end
    session[:u2f_failed_count] = 0

  end

  def create
    if params[:u2f_response].blank?
      flash[:error] = 'Could not add key'
      redirect_to u2fs_path and return
    end
    response = {}
    u2f_response = U2F::RegisterResponse.load_from_json(params[:u2f_response])

    exist = current_user.u2fs.find_by(key_handle: u2f_response.key_handle)
    if exist
      @error = 'This U2F device has already been registered.'
      response['error'] = 'This U2F device has already been registered.'
    end

    begin
      u2f_registration = u2f.register!(session[:challenges], u2f_response)

      current_user.u2fs.create!(nick_name:   params['nick_name'],
                                certificate: u2f_registration.certificate,
                                key_handle:  u2f_registration.key_handle,
                                public_key:  u2f_registration.public_key,
                                counter:     u2f_registration.counter)
    rescue U2F::Error => e
      response['error'] = 'Unable to register: ' + e.class.name
    ensure
      session.delete(:challenges)
    end
    @u2fs = current_user.u2fs

    render json: response
  end

  def update
    @u2f = current_user.u2fs.find_by(id: params[:id])
    if @u2f.update(u2f_params)
      flash.now[:notice] = 'Successfully updated'
    else
      flash.now[:warning] = 'Could not update'
    end

    render json: { result: 'success', u2f_description: u2f.nick_name }
  end

  def destroy
    redirect_to root_path and return unless current_user
    response = {}
    u2f = current_user.u2fs.find_by(id: params['id'])
    if u2f
      u2f.destroy
      response['u2f_device_id'] = u2f.id
    else
      response['error'] = 'There is no data for selected U2f Token'
    end

    render json: response
  end
end

private

def u2f_params
  params.require(:u2f).permit(:nick_name)
end
