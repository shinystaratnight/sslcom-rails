# frozen_string_literal: true

module Pillar
  module Core
    class Component
      attr_accessor :name, :description, :path, :component_class, :instance, :mount, :key, :menu

      def initialize(*args)
        args[0].each do |key, value|
          send("#{key}=", value)
        end
      end
    end
  end
end
