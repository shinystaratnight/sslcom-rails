# frozen_string_literal: true

class OtpsController < ApplicationController
  skip_before_action :verify_u2f_authentication
  before_action :require_user

  def login
    session[:authenticated] = false
    unless current_user&.authy_user_id
      flash[:error] = 'No registered phone number'
      redirect_to u2fs_path and return
    end
    # Send SMS. Response:  {"success"=>true, "message"=>"SMS token was sent", "cellphone"=>"+12-123-123-3456"}
    response = Authy::API.request_sms(id: current_user.authy_user_id)
    @authy_user_id = current_user.authy_user_id.to_s
  end

  def verify_login
    session[:authenticated] = false
    response = Authy::API.verify(id: current_user.authy_user_id,
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

    if current_user&.authy_user_id.blank?
      flash[:error] = 'Not registered for verification code!'
      redirect_to u2fs_path and return
    end

    begin
      @authy_user_id = current_user.authy_user_id.to_s
      response = send_email(@authy_user_id)
      # Raise error unless response success, so that we can log exact error
      raise 'Please try again.' unless response && response['success'] == 'success'
    rescue => e
      # log failure? response['message']
      flash[:error] = 'Something went wrong.'
    end

    render :login
  end

  def email
    # We must have values for country and phone to register user (prior to sending the email)
    country_name = params['otp']['country'] || current_user.country if params['otp']
    phone = params['otp']['phone'] || current_user.phone if params['otp']
    unless phone && country_name
      render json: { error: 'Please complete your phone details' } and return
    end

    result = { id: nil, error: nil }
    country = Country.find_by(name: country_name)

    begin
      # Get existing authy_id of current_user, or register user with authy
      authy_user_id = if current_user.authy_user_id.present?
                        current_user.authy_user_id
                      elsif authy_user = register_authy_user(current_user.email, phone, country.num_code)
                        authy_user['id']
                      end

      result[:id] = authy_user_id if authy_user_id.present?

      response = send_email(authy_user_id)
      # Raise error unless response success, so that we can log exact error
      raise 'Please try again.' unless response && response['success'] == 'success'
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
      raise 'Please try again.' unless params['otp']

      phone = params[:otp][:phone] || current_user&.phone
      country = Country.find_by(id: params['otp']['country']) if params['otp']['country']
      country ||= Country.find_by(name: current_user&.country )
      # We must have form values for country and phone
      raise 'Please try again.' unless phone.present? && country.present?

      current_user.phone = phone
      current_user.country = country.name
      raise 'Phone already verified!' unless current_user.requires_phone_verification?

      authy_user = register_authy_user(current_user.email, phone, country.num_code)

      raise 'Please check the number you provided, and try again.' if authy_user['id'].blank?

      result[:id] = authy_user['id']
      response = Authy::API.request_sms(id: authy_user['id']) if authy_user['id']
      raise 'Please try again.' unless response

      raise response['message'] unless response['success'] == true
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
    existing_authy_user_id = current_user&.authy_user_id
    current_user.phone = otp_params['phone']
    country_id = params[:otp][:country]
    current_user.country = Country.find_by(id: country_id)&.name
    current_user.authy_user_id = otp_params['authy_user_id']

    begin
      # If user data are not valid
      raise 'Please submit the information again.' unless current_user.valid?

      response = Authy::API.verify(id: current_user.authy_user_id,
                                   token: otp_params['verification_code'].strip)

      # Failed code verification
      raise 'Incorrect code, please try again.' unless response.ok?

      # Destroy user session // log failed login attempt etc

      # Successful code verification
      result[:success] = 'true'
      session[:authenticated] = true
      flash.now[:notice] = 'Phone number successfully verified.'
      # Update user information (phone, country, authy_user_id) only after successful verification
      current_user.save if current_user.phone && current_user.country && current_user.changed?

      # Remove previous authy user
      delete_authy_user(existing_authy_user_id)
    rescue => e
      # Log failed attempt to verify phone
      result[:error] = 'Something went wrong. ' + e.message
    end

    render json: result
  end

  private

  def otp_params
    params.require(:otp).permit(:verification_code, :authy_user_id, :phone, :country)
  end

  def register_authy_user(email, phone, country_code)
    return unless email && phone && country_code

    authy_user = Authy::API.register_user(email: email,
                                          cellphone: phone,
                                          country_code: country_code)
    authy_user
  end

  def send_email(authy_user_id)
    uri = URI.parse("https://api.authy.com/protected/json/email/#{authy_user_id}")
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

  def delete_authy_user(existing_authy_user_id)
    return unless existing_authy_user_id

    Authy::API.delete_user(id: existing_authy_user_id) if existing_authy_user_id != current_user.authy_user_id
  end
end
