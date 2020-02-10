# frozen_string_literal: true

SslCom::Application.configure do
  APP_URL = "http://#{Settings.dev_portal_domain}:3000"
  MIGRATING_FROM_LEGACY = false
  MIGRATING_SURLS_TO_SSL_GS = false
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.cache_store = :dalli_store

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  config.action_mailer.delivery_method = :letter_opener_web
  config.action_mailer.perform_deliveries = true

  config.eager_load = false

  config.to_prepare do
    BillingProfile.password = 'kama1jama1'
  end

  config.assets.debug = false
  config.assets.compile = true
  config.assets.digest = false
  config.assets.quiet = true
  # config.log_level = :info

  unless Rails.env.test?
    config.middleware.use Rack::SslEnforcer,
                          only: [%r{^/certificates/.*?/buy}, %r{^/login}, %r{^/account(/new)?}, %r{^/user_session/new},
                                 %r{^/users?/new(/affiliates)?}, %r{^/password_resets/new}, %r{^/orders/new}, %r{^/secure/allocate_funds},
                                 %r{^/certificate_orders/.*}]
  end

  ActiveMerchant::Billing::Base.mode = :test
  # GATEWAY_TEST_CODE = 1.0
  # END ActiveMerchant configuration

  config.middleware.insert_before 0, 'Rack::Cors' do
    allow do
      origins '*'
      resource '*', headers: :any, methods: :any
    end
  end

  # AWS S3
  config.paperclip_defaults = {
    storage: :s3,
    bucket: Rails.application.secrets.s3_bucket,
    s3_region: Rails.application.secrets.s3_region,
    s3_host_name: "s3-#{Rails.application.secrets.s3_region}.amazonaws.com"
  }

  config.after_initialize do
    Bullet.enable = true
    Bullet.bullet_logger = true
  end
end

require "#{Rails.root}/lib/force_ssl.rb"
