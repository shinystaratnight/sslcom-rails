require "pillar/core"
require "pillar/theme"
require "pillar/pages/engine"

module Pillar
  module Pages
    class << self
      def version
        Pillar::Pages::VERSION
      end

      def root
        @root ||= Pathname.new(File.expand_path("../..", __dir__))
      end
    end
  end
end
