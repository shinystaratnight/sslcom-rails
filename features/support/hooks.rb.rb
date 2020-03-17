#After('@firewatir') do
#  @browser.goto APP_URL + logout_path
#end
#
##tests that are testing authlogic directly should run remote server (will require a separate server is running)
##other tests can run inline and should use UserSession.create(user_obj) to login, as opposed to
##logging in manually through the login page and things like controller.session['user_credentials'] are then accessible
##@driver = {browser: :firefox, remote_server: false, name: :selenium}#:rack_test :webkit :firewatir :selenium}
#
#Before('@firewatir') do
#  Fixtures.reset_cache
#  fixtures_folder = File.join(Rails.root, 'test', 'fixtures')
#  fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml') }
#  Fixtures.create_fixtures(fixtures_folder, fixtures)
#  if RUBY_PLATFORM =~ /(i486|x86_64)-linux/
#    require 'firewatir'
#    Watir::Browser.default = 'firefox'
#  else
#    case RUBY_PLATFORM
#    when /darwin/
#      Watir::Browser.default = 'safari'
#    when /win32|mingw/
#      Watir::Browser.default = 'ie'
#    when /java/
#      Watir::Browser.default = 'celerity'
#    else
#      raise "This platform is not supported (#{RUBY_PLATFORM})"
#    end
#  end
#  @browser = Watir::Browser.new
#end
#
#
##
##Before('@remote','@selenium') do
##  @driver = {browser: :firefox, remote_server: true, name: :selenium}#:rack_test :webkit :firewatir :selenium}
##end
##
##Before('@inline','@selenium') do
##  @driver = {browser: :firefox, remote_server: false, name: :selenium}#:rack_test :webkit :firewatir :selenium}
##end
##
##Before('@inline','@webkit') do
##  @driver = {browser: :firefox, remote_server: false, name: :webkit}#:rack_test :webkit :firewatir :selenium}
##end
##
##Before('@inline','@rack_test') do
##  @driver = {browser: :firefox, remote_server: false, name: :rack_test}#:rack_test :webkit :firewatir :selenium}
##end
##
##
#
#
#
