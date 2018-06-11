namespace :memcached do
  desc 'Clears the SSL cache'
  task :flush => :environment do
    Rails.cache.clear
  end
end