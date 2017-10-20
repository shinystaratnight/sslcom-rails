class Api::V1::APIController < ActionController::API
  include ActionController::Cookies
  include ActionController::HttpAuthentication::Basic::ControllerMethods
  include ActionController::Rendering
  include ActionController::ImplicitRender
  include ActionView::Rendering
  
  before_filter :activate_authlogic
    
  TEST_SUBDOMAIN = 'sws-test'
  
  respond_to :json
  
  rescue_from MultiJson::DecodeError do |exception|
    render text: exception.to_s, status: 422
  end
  
  private
  
  def set_test
    @test = request.subdomain==TEST_SUBDOMAIN || %w{development test}.include?(Rails.env)
  end
  
  def activate_authlogic
    Authlogic::Session::Base.controller = Authlogic::ControllerAdapters::RailsAdapter.new(self)
  end
  
  def render_200_status
    render template: @template, status: 200
  end
  
  def render_400_status
    render template: @template, status: 200
  end
  
  def render_500_error(e)
    logger.error e.message
    e.backtrace.each { |line| logger.error line }
    error(500, 500, 'server error')
  end
end
