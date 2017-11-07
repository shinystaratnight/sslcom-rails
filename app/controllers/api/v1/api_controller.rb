require 'will_paginate/array'

class Api::V1::APIController < ActionController::API
  include SerializerHelper
  include ActionController::Cookies
  include ActionController::HttpAuthentication::Basic::ControllerMethods
  include ActionController::Rendering
  include ActionController::ImplicitRender
  include ActionView::Rendering
  
  before_filter :activate_authlogic
  after_filter  :set_access_control_headers

  TEST_SUBDOMAIN = 'sws-test'
  PER_PAGE_DEFAULT = 10
  
  respond_to :json
  
  rescue_from MultiJson::DecodeError do |exception|
    render text: exception.to_s, status: 422
  end
  
  private
  
  def error(status, code, message)
    json = {response_type: 'ERROR', response_code: code, message: message}.to_json
    render json: json, status: status
  end
  
  def set_test
    @test = request.subdomain==TEST_SUBDOMAIN || %w{development test}.include?(Rails.env)
  end
  
  def activate_authlogic
    Authlogic::Session::Base.controller = Authlogic::ControllerAdapters::RailsAdapter.new(self)
  end
  
  def render_200_status_noschema
    json = if @result.errors.empty?
      serialize_model(@result)['data']['attributes']
    else
      {errors: @result.errors}
    end
    render json: json, status: 200
  end
  
  def render_200_status
    render template: @template, status: 200
  end
  
  def render_400_status
    render template: @template, status: 400
  end
  
  def render_500_error(e)
    logger.error e.message
    e.backtrace.each { |line| logger.error line }
    error(500, 500, 'server error')
  end

  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end  
  
  def has_api_access?
    ak = params[:account_key]
    sk = params[:secret_key]
    return false if ak.blank? || sk.blank?
    @team ||= SslAccount.joins(:api_credential)
      .where(api_credential: {account_key: ak, secret_key: sk}).last
    !@team.nil?
  end
end
