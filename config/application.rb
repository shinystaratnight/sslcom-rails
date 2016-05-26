require File.expand_path('../boot', __FILE__)
require 'oauth/rack/oauth_filter'
require 'rack/ssl-enforcer'
require 'rails/all'

Bundler.setup
# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

CLIENT_OPTIONS=["ssl.com","certassure"]
DEPLOYMENT_CLIENT=CLIENT_OPTIONS[0]

module SslCom
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib)

    Bundler.require(*Rails.groups)
    Config::Integration::Rails::Railtie.preload

    # Add additional load paths for your own custom dirs
    %w(observers mailers middleware).each do |dir|
      config.autoload_paths << "#{config.root}/app/#{dir}"
    end

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    config.action_view.javascript_expansions[:defaults] = %w(jquery.min jquery_ujs)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation]
    #config.action_mailer.default_url_options = { :host => Settings.actionmailer_host }

    #machinist generator
    # config.generators do |g|
    #   g.fixture_replacement :machinist
    # end

    #turn off strong parameters
    config.action_controller.permit_all_parameters = true

    config.generators do |g|
      g.test_framework :rspec,
        :fixtures => true,
        :view_specs => false,
        :helper_specs => false,
        :routing_specs => false,
        :controller_specs => true,
        :request_specs => true
      g.fixture_replacement :factory_girl,
        :dir => "spec/factories"
    end #See more at: http://everydayrails.com/2012/03/12/testing-series-rspec-setup.html#sthash.nLKiuyz7.dpuf

    config.middleware.use OAuth::Rack::OAuthFilter

    #config.force_ssl = true
    config.middleware.use Rack::SslEnforcer,
      only: [%r(^/certificates/.*?/buy), %r(^/login), %r{^/account(/new)?}, %r(^/user_session/new), %r{^/users?/new(/affiliates)?},
             %r(^/password_resets/new), %r(^/orders/new), %r(^/secure/allocate_funds), %r(^/certificate_orders/.*)]

    config.middleware.insert_before 0, "Rack::Cors" do
      allow do
        origins '*'
        resource '/certificate/*',
                 :headers => :any,
                 :methods => [:get, :post, :delete, :put, :options, :head],
                 :max_age => 0
      end
    end

    # Enable the asset pipeline
    config.assets.enabled = true
    self.paths['config/database'] = 'config/client/certassure/database.yml' if DEPLOYMENT_CLIENT=~/certassure/i && Rails.root.to_s=~/Development/
  end
end

require "#{Rails.root}/lib/base.rb"
require "#{Rails.root}/lib/asset_tag_helper.rb"
require "#{Rails.root}/lib/array.rb"
require "#{Rails.root}/lib/range.rb"
require "#{Rails.root}/lib/in_words.rb"
require "#{Rails.root}/lib/kernel.rb"
require "#{Rails.root}/lib/money.rb"
# require "#{Rails.root}/lib/subdomain-fu.rb"
require "#{Rails.root}/lib/force_ssl.rb"
require "#{Rails.root}/lib/domain_constraint.rb"
require "#{Rails.root}/lib/preferences.rb"
require "#{Rails.root}/lib/active_record.rb"
require "will_paginate"

#try to figure this out for heroku and rails 3
#class Fixnum; include InWords; end
#class Bignum; include InWords; end

DB_STRING_MAX_LENGTH = 255
DB_TEXT_MAX_LENGTH = 40000
HTML_TEXT_FIELD_SIZE = 20
AMOUNT_FIELD_SIZE = 10
ADDRESS_FIELD_SIZE = 30
SERVER_SIDE_CART = false
SQL_LIKE = Rails.configuration.database_configuration[Rails.env]['adapter'].
  downcase=='postgresql' ? 'ilike' : 'like'

#uncomment to track down bugs on heroku production
#ActiveRecord::Base.logger.level = 0 # at any time
ActiveMerchant::Billing::CreditCard.require_verification_value=false


