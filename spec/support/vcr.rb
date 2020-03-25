# frozen_string_literal: true

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.ignore_localhost = true
  config.hook_into :webmock
  config.allow_http_connections_when_no_cassette = true
end
