# frozen_string_literal: true

# if defined?(DatabaseCleaner)
#   # cleaning the database using database_cleaner
#   DatabaseCleaner.strategy = :truncation
#   DatabaseCleaner.clean
# else
#   logger.warn 'add database_cleaner or update clean_db'
#   # Post.delete_all if defined?(Post)
#   User.destroy_all if defined?(User)
# end
User.connection.truncate(User.table_name)
Rails.logger.info 'APPCLEANED' # used by log_fail.rb

# begin
#   session = UserSession.find
#   session.destroy
# rescue => e
#   Rails.logger.error e.backtrace.inspect
# end
