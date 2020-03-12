# frozen_string_literal: true

require File.expand_path('boot', __dir__)

# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
# require "action_cable/engine"
require 'sprockets/railtie'
# require 'rails/test_unit/railtie'

require './lib/middleware/catch_json_parse_errors'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

CLIENT_OPTIONS = ['ssl.com', 'certassure'].freeze
DEPLOYMENT_CLIENT = CLIENT_OPTIONS[0]

Struct.new('Expiring', :before, :after, :cert)
Struct.new('Notification', :before, :after, :domain, :expire, :reminder_type, :scanned_certificate_id)
Struct.new('Reminding', :year, :cert)

module SslcomRails
  class Application < Rails::Application
    config.before_configuration do
      env_file = File.join(Rails.root, 'config', 'local_env.yml')
      YAML.safe_load(File.open(env_file)).each do |key, value|
        ENV[key.to_s] = value
      end
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W[#{config.root}/lib]

    %w[observers mailers middleware serializers paths jobs].each do |dir|
      config.autoload_paths << "#{config.root}/app/#{dir}"
    end

    config.force_ssl = !Rails.env.test?
    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = 'utf-8'

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # Rails Api
    config.api_only = false

    # turn off strong parameters
    config.action_controller.permit_all_parameters = true

    config.generators do |g|
      g.factory_bot suffix: 'factory'
      g.test_framework :rspec, spec: true, fixture: false
      g.jbuilder false
    end

    config.middleware.insert_before ActionDispatch::ParamsParser, 'CatchJsonParseErrors'

    # Delayed Job
    config.active_job.queue_adapter = :delayed_job

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '/certificate/*',
                 headers: :any,
                 methods: %i[get post delete put options head],
                 max_age: 0
      end
    end

    # Enable the asset pipeline
    config.assets.enabled = true

    config.sass.preferred_syntax = :sass
    config.sass.line_comments = false
    config.sass.cache = false
    config.action_mailer.default_url_options = { host: 'secure.ssl.com', protocol: 'https' }
    config.active_record.raise_in_transactional_callbacks = true
    paths['config/database'] = 'config/client/certassure/database.yml' if DEPLOYMENT_CLIENT =~ /certassure/i && Rails.root.to_s =~ /Development/
  end
end

require "#{Rails.root}/lib/asset_tag_helper.rb"
require "#{Rails.root}/lib/array.rb"
require "#{Rails.root}/lib/range.rb"
require "#{Rails.root}/lib/in_words.rb"
require "#{Rails.root}/lib/kernel.rb"
require "#{Rails.root}/lib/money.rb"
require "#{Rails.root}/lib/domain_constraint.rb"
require "#{Rails.root}/lib/preferences.rb"
require "#{Rails.root}/lib/active_record_base.rb"
require "#{Rails.root}/lib/hash.rb"

DB_STRING_MAX_LENGTH = 255
DB_TEXT_MAX_LENGTH = 40_000
HTML_TEXT_FIELD_SIZE = 20
AMOUNT_FIELD_SIZE = 10
ADDRESS_FIELD_SIZE = 30
SERVER_SIDE_CART = false
# SQL_LIKE = Rails.configuration.database_configuration[Rails.env]['adapter'].
#   downcase=='postgresql' ? 'ilike' : 'like'
db_env = Rails.configuration.database_configuration[Rails.env]
db_adapter = db_env['adapter'].downcase if db_env.present?
SQL_LIKE = db_adapter == 'postgresql' ? 'ilike' : 'like'

ActiveMerchant::Billing::CreditCard.require_verification_value = false
PublicSuffix::List.default = PublicSuffix::List.parse(File.read(PublicSuffix::List::DEFAULT_LIST_PATH), private_domains: false)
