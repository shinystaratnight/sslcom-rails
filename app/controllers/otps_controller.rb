# frozen_string_literal: true

class OtpsController < ApplicationController
  def login
    session[:authenticated] = false
    unless current_user&.authy_user_id
      flash[:error] = 'No registered phone number'
      redirect_to u2fs_path and return
    end
    # Send SMS. Response:  {"success"=>true, "message"=>"SMS token was sent", "cellphone"=>"+30-XXX-XXX-XX65"}
    response = Authy::API.request_sms(id: current_user.authy_user_id)
    @authy_user_id = current_user.authy_user_id.to_s
  end

  def verify_login
    session[:authenticated] = false
    response = Authy::API.verify(id: current_user.authy_user_id,
                                 token: otp_params['verification_code'])
    if response.ok?
      redirect_to user_account_path
      session[:authenticated] = true
    else
      flash[:error] = 'Could not verify the code. Please try again or contact us.'
      render :login
    end
  end

  # Register new authy user and send SMS for phone verification
  def add_phone
    result = { id: nil, error: nil }
    phone = params[:otp][:phone] || current_user.phone
    country = params[:otp][:country]
    country_info = Country.find_by(name: country || current_user.country)

    begin
      # We must have form values for country and phone
      raise 'Please try again.' unless phone.present? && country_info.present?

      current_user.phone = phone
      current_user.country = country
      raise 'Phone already verified!' unless current_user.requires_phone_verification?

      # Register new user details with authy. Response is a hash with the authy id {"id"=>257244630}
      authy_user = Authy::API.register_user(email: current_user.email,
                                            cellphone: phone.to_s,
                                            country_code: country_info.num_code.to_i)
      raise 'Please check the number you provided, and try again.' unless authy_user['id'].present?
      result[:id] = authy_user['id']

      # Send SMS. Response:  {"success"=>true, "message"=>"SMS token was sent", "cellphone"=>"+30-XXX-XXX-XX65"}
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

    begin
      current_user.phone = otp_params['phone']
      current_user.country = otp_params['country']
      current_user.authy_user_id = otp_params['authy_user_id']
      # If user data are not valid
      raise 'Please submit the information again.' unless current_user.valid?

      response = Authy::API.verify(id: current_user.authy_user_id,
                                   token: otp_params['verification_code'])

      # Failed code verification
      raise 'Incorrect code, please try again or change your phone.' unless response.ok?
      # Destroy user session // log failed login attempt etc

      # Successful code verification
      result[:success] = 'true'
      session[:authenticated] = true
      flash.now[:notice] = 'Phone number successfully verified.'

      # Update user information (phone, country, authy_user_id) only after successful verification
      current_user.save
      # Remove previous authy user
      if existing_authy_user_id && existing_authy_user_id != current_user.authy_user_id
        Authy::API.delete_user(id: existing_authy_user_id)
      end
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
end

