# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'
require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'
require 'minitest/rails'
require 'minitest/rails/capybara'
require 'minitest/reporters'
require 'minitest/bang'

require 'webmock/minitest'
require 'mocha/minitest'
require 'database_cleaner/active_record'
require 'factory_bot'
require 'rack/utils'
require 'authlogic/test_case'
require 'declarative_authorization/maintenance'
require 'json-schema'

# capybara
require 'capybara/rails'
require 'capybara-screenshot/minitest'
require 'capybara/minitest'

require 'active_support/inflector'
require 'simplecov'

ActiveRecord::Migration.maintain_test_schema!
Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new, Minitest::Reporters::JUnitReporter.new]

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join('./test/support/**/*.rb')].sort.each { |f| require f }

DatabaseCleaner.clean_with :deletion
DatabaseCleaner.strategy = :truncation, { except: %w[roles reminder_triggers server_software] }

Paperclip::Attachment.default_options[:path] = if ENV['PARALLEL_TEST_GROUPS']
                                                 ":rails_root/public/system/:rails_env/#{ENV['TEST_ENV_NUMBER'].to_i}/:class/:attachment/:id_partition/:filename"
                                               else
                                                 ':rails_root/public/system/:rails_env/:class/:attachment/:id_partition/:filename'
                                               end
WebMock.enable!

module Minitest
  class Spec
    class_eval do
      include SessionHelper
      include SetupHelper
      include Asserts
      include Authlogic::TestCase

      before :suite do
        Delayed::Worker.delay_jobs = false
        DatabaseCleaner.start
      end

      after :suite do
        DatabaseCleaner.clean
      end
    end
  end
end

module ActionDispatch
  class IntegrationTest
    include Capybara::Screenshot::MiniTestPlugin
    include Capybara::DSL
    include Capybara::Minitest::Assertions

    # Reset sessions and driver between tests
    teardown do
      Capybara.reset_sessions!
      Capybara.use_default_driver
    end
  end
end

module ActiveSupport
  class TestCase
    class_eval do
      include SessionHelper
      include SetupHelper
      include Asserts
      include Authlogic::TestCase

      before :suite do
        Delayed::Worker.delay_jobs = false
        DatabaseCleaner.start
      end

      after :suite do
        DatabaseCleaner.clean
      end
    end
  end
end

# if RUBY_VERSION >= '2.6.0'
#   if Rails.version < '5'
#     class ActionController::TestResponse < ActionDispatch::TestResponse
#       def recycle!
#         # Hack to avoid MonitorMixin double-initialize error:
#         @mon_mutex_owner_object_id = nil
#         @mon_mutex = nil
#         initialize
#       end
#     end
#   end
# end