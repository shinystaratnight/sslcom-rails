# frozen_string_literal: true

require 'simplecov'

ENV['RAILS_ENV'] = 'test'
require File.expand_path('../config/environment', __dir__)

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
require 'minitest/bang'
require 'capybara/rails'
require 'capybara-screenshot/minitest'
require 'capybara/minitest'

ActiveRecord::Migration.maintain_test_schema!

Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new, Minitest::Reporters::JUnitReporter.new]

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join('./test/support/**/*.rb')].sort.each { |f| require f }

DatabaseCleaner.clean_with :truncation
DatabaseCleaner.strategy = :truncation

Paperclip::Attachment.default_options[:path] = if ENV['PARALLEL_TEST_GROUPS']
                                                 ":rails_root/public/system/:rails_env/#{ENV['TEST_ENV_NUMBER'].to_i}/:class/:attachment/:id_partition/:filename"
                                               else
                                                 ':rails_root/public/system/:rails_env/:class/:attachment/:id_partition/:filename'
                                               end

module Minitest
  class Spec
    class_eval do
      include SessionHelper
      include SetupHelper
      include Asserts
      include Authlogic::TestCase

      before :each do
        DatabaseCleaner.start
        Delayed::Worker.delay_jobs = false
      end

      after :each do
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
  end
end

module ActiveSupport
  class TestCase
    class_eval do
      include SessionHelper
      include SetupHelper
      include Asserts
      include Authlogic::TestCase
      include DatabaseCleanerSupport
    end
  end
end

if RUBY_VERSION >= '2.6.0'
  if Rails.version < '5'
    class ActionController::TestResponse < ActionDispatch::TestResponse
      def recycle!
        # Hack to avoid MonitorMixin double-initialize error:
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
