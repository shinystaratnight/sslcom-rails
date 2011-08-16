# Sets up the Rails environment for Cucumber
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
require 'cucumber/rails/world'
require 'cucumber/formatter/unicode' # Comment out this line if you don't want Cucumber Unicode support
require 'declarative_authorization/maintenance'
require 'capybara'
require 'capybara/rails'
require 'capybara/cucumber'
require 'capybara/session'
require "selenium-webdriver"
require 'factory_girl/step_definitions'

World(Authorization::Maintenance)
World(OrdersHelper)

@driver = {browser: :firefox, name: :selenium}#:rack_test :webkit :firewatir}
if @driver[:name] == :selenium
  Capybara.register_driver :selenium do |app|
    profile = Selenium::WebDriver::Firefox::Profile.new
    #profile.add_extension File.join(Rails.root, "features/support/firebug.xpi")
    Capybara::Driver::Selenium.new app, :profile => profile
  end if @driver[:browser] == :firefox
#Capybara.default_driver = :selenium
#Capybara.app_host = "http://staging1.ssl.com:3000"
#@using_selenium = Capybara.default_driver == :selenium
elsif @driver[:name] == :rack_test
  Capybara.register_driver :rack_test do |app|
    Capybara::RackTest::Driver.new(app, :browser => :firefox)
  end if @driver[:browser] == :firefox
  Capybara.default_driver = :rack_test
else
  Capybara.javascript_driver = :webkit
end

#Seed the DB
module FixtureAccess

  def self.extended(base)

    Fixtures.reset_cache
    fixtures_folder = File.join(RAILS_ROOT, 'test', 'fixtures')
    fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml') }
    fixtures += Dir[File.join(fixtures_folder, '*.csv')].map {|f| File.basename(f, '.csv') }

    Fixtures.create_fixtures(fixtures_folder, fixtures)    # This will populate the test database tables

    (class << base; self; end).class_eval do
      @@fixture_cache = {}
      fixtures.each do |table_name|
        table_name = table_name.to_s.tr('.', '_')
        define_method(table_name) do |*fixture_symbols|
          @@fixture_cache[table_name] ||= {}

          instances = fixture_symbols.map do |fixture_symbol|
            if fix = Fixtures.cached_fixtures(ActiveRecord::Base.connection, table_name)[fixture_symbol.to_s]
              @@fixture_cache[table_name][fixture_symbol] ||= fix.find  # find model.find's the instance
            else
              raise StandardError, "No fixture with name '#{fixture_symbol}' found for table '#{table_name}'"
            end
          end
          instances.size == 1 ? instances.first : instances
        end
      end
    end
  end

end
World(FixtureAccess)

#require 'ruby-debug-ide'

# Comment out the next two lines if you're not using RSpec's matchers (should / should_not) in your steps.
# since updated to 0.1.99.22, I read that these can be commented out - see http://forums.pragprog.com/forums/95/topics/2102
#require 'cucumber/rails/rspec'
#require 'webrat/rspec-rails'

# Make visible for testing
#BaseController.send(:public, :logged_in?, :current_user, :authorized?)

#require 'spec' # since updated to 0.1.99.22, I read that this can be commented out - see http://forums.pragprog.com/forums/95/topics/2102
#require 'spec/expectations'
require 'email_spec/cucumber'

if @driver==:firewatir
  if RUBY_PLATFORM =~ /(i486|x86_64)-linux/
    require 'firewatir'
    Watir::Browser.default = 'firefox'
  else
    case RUBY_PLATFORM
    when /darwin/
      Watir::Browser.default = 'safari'
    when /win32|mingw/
      Watir::Browser.default = 'ie'
    when /java/
      Watir::Browser.default = 'celerity'
    else
      raise "This platform is not supported (#{RUBY_PLATFORM})"
    end
  end
  @browser = Watir::Browser.new
end

ActionMailer::Base.delivery_method = :test

@popup_text = ""

Before do
  # Scenario setup
  ActionMailer::Base.deliveries.clear
end

at_exit do
  # Global teardown
  @browser.close if @driver==:firewatir
  #TempFileManager.clean_up
end