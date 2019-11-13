require 'simplecov'
SimpleCov.start 'rails' do
add_filter '/bin/'
 add_filter '/db/'
 add_filter '/test/'
 add_filter '/config/'
 add_group "Models", "app/models"
 add_group "Controllers", "app/controllers"
 add_group "Services", "app/services"
 add_group "Helpers", "app/helpers"
 add_group "Lib", "lib/"
end

ENV["RAILS_ENV"] = 'test'
require File.expand_path('../../config/environment', __FILE__)

require 'rails/test_help'
require 'minitest/rails'
require 'minitest/pride'
require 'minitest/reporters'
require 'webmock/minitest'
require 'mocha/setup'
require 'database_cleaner'
require 'factory_bot'
require 'rack/utils'
require 'authlogic/test_case'
require 'declarative_authorization/maintenance'
require 'json-schema'

ActiveRecord::Migration.maintain_test_schema!

Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join('./test/support/**/*.rb')].sort.each { |f| require f }

include SessionHelper
include SetupHelper
include MailerHelper
include Authorization::TestHelper
include AuthorizationHelper
include ApiSetupHelper

DatabaseCleaner.clean_with :truncation
DatabaseCleaner.strategy = :truncation

class Minitest::Spec
  include Authlogic::TestCase
  include Rails.application.routes.url_helpers

  before :each do
    disable_authorization
    activate_authlogic
    DatabaseCleaner.start
    Delayed::Worker.delay_jobs = false
  end

  after :each do
    DatabaseCleaner.clean
    clear_email_deliveries
  end
end

if RUBY_VERSION>='2.6.0'
  if Rails.version < '5'
    class ActionController::TestResponse < ActionDispatch::TestResponse
      def recycle!
        # hack to avoid MonitorMixin double-initialize error:
        @mon_mutex_owner_object_id = nil
        @mon_mutex = nil
        initialize
      end
    end
  end
end

# Forces all threads to share the same connection. This works on
# Capybara because it starts the web server in a thread.
# ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection

# Ubuntu packages to run test suite setup:
# =========================================
# see test/support/ubuntu_packages.rb
