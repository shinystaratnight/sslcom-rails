## Sets up the Rails environment for Cucumber
#ENV["RAILS_ENV"] = "test"
#require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
#require 'cucumber/rails/world'
#require 'cucumber/formatter/unicode' # Comment out this line if you don't want Cucumber Unicode support
#require 'declarative_authorization/maintenance'
#
##bypasses declarative authorization to allow creating objects
##World(Authorization::Maintenance)
#World(OrdersHelper)
#
##Seed the DB
#module FixtureAccess
#
#  def self.extended(base)
#
#    Fixtures.reset_cache
#    fixtures_folder = File.join(Rails.root, 'test', 'fixtures')
#    fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml') }
#    fixtures += Dir[File.join(fixtures_folder, '*.csv')].map {|f| File.basename(f, '.csv') }
#
#    Fixtures.create_fixtures(fixtures_folder, fixtures)    # This will populate the test database tables
#
#    (class << base; self; end).class_eval do
#      @@fixture_cache = {}
#      fixtures.each do |table_name|
#        table_name = table_name.to_s.tr('.', '_')
#        define_method(table_name) do |*fixture_symbols|
#          @@fixture_cache[table_name] ||= {}
#
#          instances = fixture_symbols.map do |fixture_symbol|
#            if fix = Fixtures.cached_fixtures(ActiveRecord::Base.connection, table_name)[fixture_symbol.to_s]
#              @@fixture_cache[table_name][fixture_symbol] ||= fix.find  # find model.find's the instance
#            else
#              raise StandardError, "No fixture with name '#{fixture_symbol}' found for table '#{table_name}'"
#            end
#          end
#          instances.size == 1 ? instances.first : instances
#        end
#      end
#    end
#  end
#
#end
#World(FixtureAccess)
#
## Make visible for testing
##BaseController.send(:public, :logged_in?, :current_user, :authorized?)
#
##require 'spec' # since updated to 0.1.99.22, I read that this can be commented out - see http://forums.pragprog.com/forums/95/topics/2102
##require 'spec/expectations'
#require 'email_spec/cucumber'
#
#ActionMailer::Base.delivery_method = :test
#
#@popup_text = ""
#
#Before do
#  # Scenario setup
#  ActionMailer::Base.deliveries.clear
#end
#
#at_exit do
#  # Global teardown
#  @browser.close if @driver && @driver[:name]==:firewatir
#  #TempFileManager.clean_up
#end
