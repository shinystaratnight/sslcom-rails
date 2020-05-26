ENV["RAILS_ENV"] ||= "test"

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "shoulda/matchers"
require "capybara/rspec"
require "capybara-screenshot/rspec"
require "selenium/webdriver"
require "faker"
require "factory_bot_rails"
require "database_cleaner"
require "timecop"
require "simplecov"
require "simplecov-console"
require "simplecov-material"
require "shields_badge"

SimpleCov.formatters = [
  SimpleCov::Formatter::MaterialFormatter,
  SimpleCov::Formatter::ShieldsBadge,
  SimpleCov::Formatter::Console
]

SimpleCov.start

Dir[File.join(__dir__, "helpers/**/*.rb")].sort.each { |f| require f }
Dir[File.join(__dir__, "shared_contexts/**/*.rb")].sort.each { |f| require f }

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

root = defined?(ENGINE_ROOT) ? Pathname.new(ENGINE_ROOT) : Rails.root

Dir[root.join("spec/support/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new

  [
    "headless",
    "window-size=1920x1080",
    "disable-gpu"
  ].each { |arg| options.add_argument(arg) }

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.default_driver = :selenium_chrome_headless
Capybara.javascript_driver = :selenium_chrome_headless
Capybara.server = :puma, {Silent: true}
Capybara::Screenshot.autosave_on_failure = false
Capybara::Screenshot.webkit_options = {width: 1920, height: 1080}
