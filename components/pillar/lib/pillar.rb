require "pillar/configuration"
require "pillar/engine"

module Pillar
  class << self
    attr_accessor :config
    
    def version
      Pillar::VERSION
    end

    def root
      @root ||= Pathname.new(File.expand_path("..", __dir__))
    end

    def configure
      @config = Configuration.new
      yield config
    end
  end
end
