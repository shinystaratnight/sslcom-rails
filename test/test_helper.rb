ENV["RAILS_ENV"] = 'test'
require File.expand_path('../../config/environment', __FILE__)

require 'rails/test_help'
require 'minitest/rails'
require 'minitest/pride'
require 'minitest/reporters'
require 'mocha/setup'
require 'database_cleaner'
require 'factory_girl'
require 'rack/utils'
require 'capybara'
require 'capybara/rails'
require 'capybara/dsl'
require 'capybara-screenshot/minitest'
require 'headless'
require 'authlogic/test_case'
require 'rack_session_access/capybara'
require 'declarative_authorization/maintenance'
require 'selenium-webdriver'
require 'json-schema'

Capybara.app = Rack::ShowExceptions.new(SslCom::Application)

ActiveRecord::Migration.maintain_test_schema!

Minitest::Reporters.use!

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join('./test/support/**/*.rb')].sort.each { |f| require f }

include SessionHelper
include SetupHelper
include MailerHelper
include Authorization::TestHelper
include AuthorizationHelper

DatabaseCleaner.clean_with :truncation
DatabaseCleaner.strategy = :truncation

class Minitest::Spec
  include Authlogic::TestCase
  include Capybara::DSL
  include Capybara::Screenshot::MiniTestPlugin
  include Rails.application.routes.url_helpers

  before :each do
    disable_authorization
    activate_authlogic
    DatabaseCleaner.start
    @headless = Headless.new
    @headless.start
  end

  after :each do
    DatabaseCleaner.clean
    Capybara.reset_sessions!
    Capybara.use_default_driver
    Capybara.app_host = nil
    delete_all_cookies
    clear_email_deliveries
  end
end

Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.default_driver    = :selenium
Capybara.javascript_driver = :selenium

Capybara::Screenshot.autosave_on_failure = false

# Forces all threads to share the same connection. This works on
# Capybara because it starts the web server in a thread.
# ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection

# Ubuntu packages to run test suite setup:
# =========================================
# see test/support/ubuntu_packages.rb
