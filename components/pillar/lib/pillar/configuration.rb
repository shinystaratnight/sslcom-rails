module Pillar
  class Configuration
    attr_accessor :theme, :components

    def initialize
      self.theme = "default"
      self.components = []
    end
  end
end
