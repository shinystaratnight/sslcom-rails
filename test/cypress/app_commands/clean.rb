# frozen_string_literal: true

if defined?(DatabaseCleaner)
  # cleaning the database using database_cleaner
  DatabaseCleaner.strategy = :truncation, { except: %w[reminder_triggers roles] }
  Authorization::Maintenance.without_access_control { DatabaseCleaner.clean }
else
  logger.warn 'add database_cleaner or update clean_db'
end

Rails.logger.info 'APPCLEANED' # used by log_fail.rb
