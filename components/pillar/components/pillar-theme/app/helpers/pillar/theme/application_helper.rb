# frozen_string_literal: true

require "webpacker/helper"
require "pillar/theme/active_link_to"

module Pillar
  module Theme
    module ApplicationHelper
      include Pagy::Frontend
      include Webpacker::Helper
      include Pillar::Theme::ActiveLinkTo

      def current_webpacker_instance
        Pillar::Theme.webpacker
      end
    end
  end
end
