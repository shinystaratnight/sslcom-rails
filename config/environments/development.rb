# frozen_string_literal: true

Rails.application.configure do
  APP_URL = "http://#{Settings.dev_portal_domain}:3000"

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true
  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.cache_store = :dalli_store

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  config.action_mailer.delivery_method = :letter_opener_web
  config.action_mailer.perform_deliveries = true

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  config.to_prepare do
    BillingProfile.password = 'kama1jama1'
  end

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = false
  config.assets.compile = true
  config.assets.digest = false
  config.assets.quiet = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # config.middleware.use Rack::SslEnforcer,
  #                       only: [%r{^/certificates/.*?/buy}, %r{^/login}, %r{^/account(/new)?}, %r{^/user_session/new},
  #                              %r{^/users?/new(/affiliates)?}, %r{^/password_resets/new}, %r{^/orders/new}, %r{^/secure/allocate_funds},
  #                              %r{^/certificate_orders/.*}]

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

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

  # Raises error for missing translations
  config.action_view.raise_on_missing_translations = true

  config.log_level = :debug
end
