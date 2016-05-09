SslCom::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb
  APP_URL = "http://ssldocs.heroku.com"
  MIGRATING_FROM_LEGACY = false

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.cache_store = :dalli_store

  # For nginx:
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :error

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_assets = false

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:    "email-smtp.us-east-1.amazonaws.com",
    port:       465,
    enable_starttls_auto: true,
    ssl: true,
    authentication: :login,
    user_name: "AKIAJNCUJGKABXHTVP3A",
    password: "AqbmBAfXEHru+nWEkuHiAJbWl+8KSUx3qswKJXW8Inr5"
  }

  config.to_prepare do
    BillingProfile.password = "kama1jama1"
  end

  config.log_level = :info
  # END ActiveMerchant configuration
  config.eager_load = true
end

SubdomainFu.configure do |config|
  config.tld_sizes = {development: 1, test: 1, production: 1} # set all at once (also the defaults)
  config.mirrors = %w(www)
  config.preferred_mirror = "www"
end

