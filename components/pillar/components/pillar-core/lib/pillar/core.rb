# frozen_string_literal: true

require "pillar"
require "pillar/core/application_responder"
require "pillar/core/version"
require "pillar/core/menu_item"
require "pillar/core/component"
require "pillar/core/engine"
require "pillar/core/current_attributes"
require "groupdate"
require "haml-rails"
require "pagy"
require "ransack"
require "responders"

module Pillar
  module Core
    class << self
      def version
        Pillar::Core::VERSION
      end

      def root
        @root ||= Pathname.new(File.expand_path("../..", __dir__))
      end

      def components
        @components ||= []
      end

      def menu
        @menu ||= build_menu
      end

      def register(component = nil)
        if component&.is_a?(Component)
          component.instance = "#{component.component_class}::Engine".constantize

          if component.mount
            Pillar::Engine.routes.append do
              mount component.instance, at: component.path, as: component.key
            end
          end

          components.push(component)
        end
      end

      def unregister(name = nil)
        # TODO:
        # Rails.application.routes.draw // possible to dynamically remove route
        # reload_routes!
      end

      def component_loaded?(key)
        components.any? do |component|
          component.key == key
        end
      end

      private

      def build_menu
        components.map do |component|
          unless component.menu.nil?
            component.menu.each do |item|
              item.link = component.instance.routes.url_helpers.send(item.path)
            end
          end
        end
  
        components.map(&:menu).flatten.compact.group_by{ |item| item.group }
      end
    end
  end
end
