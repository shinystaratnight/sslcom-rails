#require 'database_cleaner'
#require 'database_cleaner/cucumber'
#DatabaseCleaner.clean_with :truncation # clean once to ensure clean slate
#DatabaseCleaner.strategy = :truncation # for selenium
##DatabaseCleaner.strategy = :transaction
#
#Before('@no-txn') do
#  DatabaseCleaner.start
#end
#
#After('@no-txn') do
#  DatabaseCleaner.clean
#end
#
