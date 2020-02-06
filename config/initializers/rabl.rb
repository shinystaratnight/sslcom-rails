# frozen_string_literal: true

# config/initializers/rabl.rb
Rabl.configure do |config|
  config.cache_all_output = true
  config.cache_sources = !Rails.env.development? # Defaults to false
end
