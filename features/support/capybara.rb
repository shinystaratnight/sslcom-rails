require 'capybara'
require 'capybara/rails'
require 'capybara/cucumber'
require 'capybara/session'
require "selenium-webdriver"
require 'factory_girl/step_definitions'

def driver_selection
  if @driver[:remote_server]
    Capybara.app_host = "http://staging1.ssl.com:3000"
    Capybara.run_server = false
  end
  if @driver[:name] == :selenium
    Capybara.register_driver :selenium do |app|
      profile = Selenium::WebDriver::Firefox::Profile.new
      #profile.add_extension File.join(Rails.root, "features/support/firebug.xpi")
      Capybara::Driver::Selenium.new app, :profile => profile
    end if @driver[:browser] == :firefox
  #@using_selenium = Capybara.default_driver == :selenium
  elsif @driver[:name] == :rack_test
    Capybara.register_driver :rack_test do |app|
      Capybara::RackTest::Driver.new(app, :browser => :firefox)
    end if @driver[:browser] == :firefox
    Capybara.default_driver = :rack_test
  elsif @driver[:name] == :webkit
    Capybara.javascript_driver = :webkit
  end

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
end
