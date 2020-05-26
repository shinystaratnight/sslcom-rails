require "pillar/core"
require "pillar/theme"
require "pillar/authentication/engine"

# require "acts_as_tenant"
# require "devise"
# require "devise_masquerade"

module Pillar
  module Authentication
    class << self
      def version
        Pillar::Authentication::VERSION
      end

      def root
        @root ||= Pathname.new(File.expand_path("../..", __dir__))
      end
    end
  end
end
