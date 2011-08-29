# Only require this module for the cucumber and selenium environments
if ENV['RAILS_ENV'] == 'cucumber' || ENV['RAILS_ENV'] == 'selenium'
  require File.join(File.dirname(__FILE__), 'lib', 'action_mailer_cache_delivery')
end

