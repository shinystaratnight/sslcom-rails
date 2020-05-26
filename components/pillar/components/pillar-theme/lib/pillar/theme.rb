# frozen_string_literal: true

require "pillar/core"
require "pillar/theme/active_link_to"
require "pillar/theme/engine"
require "chartkick"
require "webpacker"

module Pillar
  module Theme
    class << self
      def version
        Pillar::Theme::VERSION
      end

      def root
        @root ||= Pathname.new(File.expand_path("../..", __dir__))
      end

      def webpacker
        @webpacker ||= ::Webpacker::Instance.new(
          root_path: root,
          config_path: root.join("config", "webpacker.yml")
        )
      end

      def webpacker_dev_server
        Embark::Theme.webpacker.config.dev_server
      rescue
        nil
      end
    end
  end
end
