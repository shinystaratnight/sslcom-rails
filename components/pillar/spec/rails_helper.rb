ENGINE_ROOT = Pathname.new(File.expand_path("..", __dir__))

ENV["RAILS_ENV"] = "test"

require "combustion"

Combustion.path = "spec/internal"
Combustion.initialize! :action_controller, :active_record, :action_mailer do
  config.logger = Logger.new(nil)
  config.log_level = :fatal
  # config.active_job.queue_adapter = :test
end

require "pillar/testing/rails_configuration"

# Additional RSpec configuration
#
# RSpec.configure do |config|
#   config.after(:suite) do
#     # Cleanup attachments generated during tests
#     FileUtils.rm_rf(ActiveStorage::Blob.service.root)
#   end
# end
