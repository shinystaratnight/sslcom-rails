require "pillar/core"
require "pillar/theme"
require "pillar/authority/engine"
require "rails_or"

module Pillar
  module Authority
    class << self
      def version
        Pillar::Authority::VERSION
      end

      def root
        @root ||= Pathname.new(File.expand_path("../..", __dir__))
      end
    end
  end
end
