#require 'capybara'
#require 'capybara/rails'
#require 'capybara/cucumber'
#require 'capybara/session'
#require "selenium-webdriver"
#require 'factory_girl/step_definitions'
#require 'capybara/firebug'
#
#Selenium::WebDriver::Firefox::Profile.firebug_version = '1.8.1'
#
#Capybara.app_host = "http://www.ssl.com:3000"
#
#Before("@remote") do
#  Capybara.run_server = false
#end
#
#def driver_selection
#  if @driver[:name]==:firewatir
#    if RUBY_PLATFORM =~ /(i486|x86_64)-linux/
#      require 'firewatir'
#      Watir::Browser.default = 'firefox'
#    else
#      case RUBY_PLATFORM
#      when /darwin/
#        Watir::Browser.default = 'safari'
#      when /win32|mingw/
#        Watir::Browser.default = 'ie'
#      when /java/
#        Watir::Browser.default = 'celerity'
#      else
#        raise "This platform is not supported (#{RUBY_PLATFORM})"
#      end
#    end
#    @browser = Watir::Browser.new
#  end
#end
