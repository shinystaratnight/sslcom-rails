After('@firewatir') do
  @browser.goto APP_URL + logout_path
end

#tests that are testing authlogic directly should run remote server
#other tests can run inline and should use UserSession.create(user_obj) to login, as opposed to
#logging in manually through the login page and things like controller.session['user_credentials'] are then accessible
@driver = {browser: :firefox, remote_server: false, name: :selenium}#:rack_test :webkit :firewatir :selenium}

Before('@firewatir') do
  Fixtures.reset_cache
  fixtures_folder = File.join(RAILS_ROOT, 'test', 'fixtures')
  fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml') }
  Fixtures.create_fixtures(fixtures_folder, fixtures)
  @driver = {browser: :firefox, remote_server: false, name: :firewatir}#:rack_test :webkit :firewatir :selenium}
end

Before('@remote','@selenium') do
  @driver = {browser: :firefox, remote_server: true, name: :selenium}#:rack_test :webkit :firewatir :selenium}
end

Before('@inline','@selenium') do
  @driver = {browser: :firefox, remote_server: false, name: :selenium}#:rack_test :webkit :firewatir :selenium}
end

Before do
  driver_selection
end



