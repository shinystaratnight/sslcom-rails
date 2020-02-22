# frozen_string_literal: true

# This is loaded once before the first command is executed

begin
  require 'database_cleaner'
rescue LoadError => e
  puts e.message
end

begin
  require 'factory_bot_rails'
rescue LoadError => e
  puts e.message
  begin
    require 'factory_girl_rails'
  rescue LoadError => e
    puts e.message
  end
end

begin
  require 'declarative_authorization/maintenance'
  require 'simplecov'
rescue LoadError => e
  puts e.message
end

require 'cypress_on_rails/smart_factory_wrapper'

factory = CypressOnRails::SimpleRailsFactory
factory = FactoryBot if defined?(FactoryBot)
factory = FactoryGirl if defined?(FactoryGirl)

CypressOnRails::SmartFactoryWrapper.configure(
  always_reload: !Rails.configuration.cache_classes,
  factory: factory,
  files: [
    Rails.root.join('test', 'factories.rb'),
    Rails.root.join('test', 'factories', '**', '*.rb')
  ]
)
