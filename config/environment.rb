# frozen_string_literal: false

# Load the Rails application.
require File.expand_path('application', __dir__)

# Initialize the Rails application.
Rails.application.initialize!

# for IDN (unicode names)
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

ApplicationRecord.include_root_in_json = true
