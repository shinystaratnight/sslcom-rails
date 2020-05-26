# frozen_string_literal: true

module Pillar
  module Testing
    module Helpers
      module Turbolinks
        def wait_for_turbolinks(timeout = nil)
          if has_css?(".turbolinks-progress-bar", visible: true, wait: 0.25.seconds)
            has_no_css?(".turbolinks-progress-bar", wait: timeout.presence || 5.seconds)
          end
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Pillar::Testing::Helpers::Turbolinks, type: :feature
end
