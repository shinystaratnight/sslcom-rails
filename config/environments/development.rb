SslCom::Application.configure do
  APP_URL = "http://dev-station:3000"
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = true

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  config.action_mailer.delivery_method = :test

  config.to_prepare do
    OrderTransaction.gateway =
      ActiveMerchant::Billing::AuthorizeNetGateway.new(
        :login    => '9jFL5k9E',
        :password => '8b3zEL5H69sN4Pth'
      )
    BillingProfile.password = "kama1jama1"
  end

  config.log_level = Logger::ERROR #Logger::INFO

  GATEWAY_TEST_CODE=1.0
  # END ActiveMerchant configuration

  require 'sass/plugin/rack'
  Sass::Plugin.options[:line_numbers] = true
end

