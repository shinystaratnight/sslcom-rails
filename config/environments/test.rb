# frozen_string_literal: true

SslCom::Application.configure do
  MIGRATING_FROM_LEGACY = false
  # Settings specified here will take precedence over those in config/environment.rb

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = false # ENV['CI'].present?

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = { host: 'localhost:3000' }

  config.after_initialize do
    Rails.application.routes.default_url_options = { host: 'localhost:3000' }
  end

  config.force_ssl = false

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Sort the order test cases are executed.
  config.active_support.test_order = :sorted

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr

  ActiveMerchant::Billing::Base.mode = :test

  config.eager_load = false

  config.serve_static_assets = true
  config.static_cache_control = 'public, max-age=3600'

  GATEWAY_TEST_CODE = 1.0

  config.log_level = :debug
end

# require "#{Rails.root}/lib/firewatir_url.rb"
