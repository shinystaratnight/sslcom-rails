SslCom::Application.configure do
  APP_URL = "http://dev-station:3000"
  MIGRATING_FROM_LEGACY = false
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = true

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  config.action_mailer.delivery_method = :test
  config.action_mailer.perform_deliveries = true

  config.to_prepare do
    BillingProfile.password = "kama1jama1"
  end

  ActiveMerchant::Billing::Base.mode = :test
  #config.log_level = :info

  GATEWAY_TEST_CODE=1.0
  # END ActiveMerchant configuration

  require 'sass/plugin/rack'
  Sass::Plugin.options[:line_numbers] = true
end

SubdomainFu.configure do |config|
  config.tld_sizes = {development: 1, test: 1, production: 1} # set all at once (also the defaults)
  config.mirrors = %w(www)
  config.preferred_mirror = "www"
end


