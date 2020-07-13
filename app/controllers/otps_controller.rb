# frozen_string_literal: true

class OtpsController < ApplicationController
  skip_before_action :verify_u2f_authentication
  before_action :require_user

  def login
    session[:authenticated] = false
    unless current_user&.authy_user
      flash[:error] = 'No registered phone number'
      redirect_to u2fs_path and return
    end
    # Send SMS. Response:  {"success"=>true, "message"=>"SMS token was sent", "cellphone"=>"+12-123-123-3456"}
    response = Authy::API.request_sms(id: current_user.authy_user)
    @authy_user = current_user.authy_user.to_s
  end

  def verify_login
    session[:authenticated] = false
    response = Authy::API.verify(id: current_user.authy_user,
                                 token: otp_params['verification_code'])
    if response.ok?
      session[:authenticated] = true
      set_redirect(user: current_user)
    else
      flash[:error] = 'Could not verify the code. Please try again or contact us.'
      render :login
    end
  end

  def email_login
    session[:authenticated] = false

    if current_user&.authy_user.blank?
      flash[:error] = 'Not registered for verification code!'
      redirect_to u2fs_path and return
    end

    begin
      @authy_user = current_user.authy_user.to_s
      response = send_email(@authy_user)
      # Raise error unless response success, so that we can log exact error
      raise 'Please try again.' unless response && response['success'] == 'success'
    rescue => e
      # log failure? response['message']
      flash[:error] = 'Something went wrong.'
    end

    render :login
  end

  def email
    authy_user = ''
    # We must have values for phone_prefix and phone to register user (prior to sending the email)
    phone = params['otp']['phone'] if params['otp']
    phone ||= current_user.phone

    phone_prefix = params['otp']['phone_prefix'] if params['otp']
    phone_prefix ||= current_user.phone_prefix

    if phone.blank? || phone_prefix.blank?
      render json: { error: 'Please complete your phone details' } and return
    end

    result = { id: nil, error: nil }

    begin
      # Get existing authy_id of current_user, or register user with authy
      authy_user = if current_user.authy_user.present?
                     current_user.authy_user
                   elsif authy_user = register_authy_user(current_user.email, phone, phone_prefix)
                     authy_user['id']
                   end

      result[:id] = authy_user if authy_user.present?

      response = send_email(authy_user)
      # Raise error unless response success, so that we can log exact error
      raise 'Please try again.' unless response && response['success'] == 'success'
      # current_user.verifications.create(email: current_user.email)
    rescue => e
      # log failure? response['message']
      flash[:error] = 'Something went wrong. ' + e.message
    end

    render json: result
  end

  # Register new authy user and send SMS for phone verification
  def add_phone
    result = { id: nil, error: nil }

    begin
      raise 'Please try again.' unless params['otp'] && params['otp']['phone_prefix'] && params['otp']['phone']

      phone = params['otp']['phone']
      phone_prefix = params['otp']['phone_prefix']

      # We must have form values for phone_prefix and phone
      raise 'Please try again.' unless phone.present? && phone_prefix.present?

      current_user.phone = phone
      current_user.phone_prefix = phone_prefix
      raise 'Phone already verified!' unless current_user.requires_phone_verification?

      authy_user = register_authy_user(current_user.email, phone, phone_prefix)

      raise 'Please check the number you provided, and try again.' if authy_user['id'].blank?

      result[:id] = authy_user['id']
      response = Authy::API.request_sms(id: authy_user['id']) if authy_user['id']
      raise 'Please try again.' unless response

      raise response['message'] unless response['success'] == true
      # current_user.verifications.create(sms_number: phone, sms_prefix: phone_prefix)
    rescue => e
      # log failure?
      result[:error] = 'Something went wrong. ' + e.message
    end

    render json: result
  end

  # Verify OTP code submitted by user
  # https://www.twilio.com/docs/authy/api/one-time-passwords#verify-a-one-time-password
  def verify_add_phone
    result = { error: nil, success: nil }
    existing_authy_user = current_user&.authy_user
    current_user.phone = otp_params['phone']
    current_user.phone_prefix = otp_params['phone_prefix']
    current_user.authy_user = otp_params['authy_user']
    begin
      # If user data are not valid
      raise 'Please submit the information again.' unless current_user.valid?

      response = Authy::API.verify(id: current_user.authy_user,
                                   token: otp_params['verification_code'].strip)

      # Failed code verification
      raise 'Incorrect code, please try again.' unless response.ok?

      # Destroy user session // log failed login attempt etc

      # Successful code verification
      result[:success] = 'true'
      session[:authenticated] = true
      flash.now[:notice] = 'Phone number successfully verified.'
      # Update user information (phone, phone_prefix, authy_user) only after successful verification
      current_user.save if current_user.phone && current_user.phone_prefix && current_user.changed?

      # Remove previous authy user
      delete_authy_user(existing_authy_user)
    rescue => e
      # Log failed attempt to verify phone
      result[:error] = 'Something went wrong. ' + e.message
    end

    render json: result
  end

  private

  def otp_params
    params.require(:otp).permit(:verification_code, :authy_user, :phone, :phone_prefix)
  end

  def register_authy_user(email, phone, phone_prefix)
    return unless email && phone && phone_prefix

    authy_user = Authy::API.register_user(email: email,
                                          cellphone: phone,
                                          country_code: phone_prefix)
    authy_user
  end

  def send_email(authy_user)
    return if authy_user.blank?

    uri = URI.parse("https://api.authy.com/protected/json/email/#{authy_user}")
    request = Net::HTTP::Post.new(uri)
    request['X-Authy-Api-Key'] = ENV['TWILIO_API_KEY']

    req_options = {
      use_ssl: uri.scheme == 'https'
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    response.body
  end

  def delete_authy_user(existing_authy_user)
    return unless existing_authy_user

    Authy::API.delete_user(id: existing_authy_user) if existing_authy_user != current_user.authy_user
  end
end
