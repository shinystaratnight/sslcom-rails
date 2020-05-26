# frozen_string_literal: true

require "rails/engine"

module Pillar
  module Theme
    class Engine < ::Rails::Engine
      isolate_namespace Pillar::Theme

      config.autoload_paths += Dir["#{config.root}/app/**/concerns"]

      initializer :engine_configuration do |app|
        ## Append Migrations Paths
        app.config.paths["db/migrate"].concat(config.paths["db/migrate"].expanded)

        ## Migrations Pending Check Paths
        ActiveRecord::Migrator.migrations_paths += config.paths["db/migrate"].expanded.flatten

        ## Factories Paths
        factories_path = root.join("spec", "factories")

        # This hook is provided by shared-factory gem
        ActiveSupport.on_load(:factory_bot) do
          FactoryBot.definition_file_paths.unshift(factories_path)
        end
      end

      ##
      ##  ENGINE WEBPACKER
      ##

      initializer :embark_webpacker_proxy do |app|
        next if Pillar::Theme.webpacker_dev_server.blank?

        app.middleware.insert_before(
          0,
          Webpacker::DevServerProxy,
          ssl_verify_none: true,
          webpacker: Pillar::Theme.webpacker
        )
      end

      initializer :embark_webpacker_static do |app|
        app.middleware.insert_before(
          0,
          Rack::Static,
          urls: ["/pillar-packs", "/packs-test"],
          # root: File.expand_path(File.join(__dir__, "..", "..", "..", "public"))
          root: Pillar::Theme.root.join("public").to_s
        )
      end

      config.after_initialize do
        component = Pillar::Core::Component.new(
          name: "Theme",
          description: "Pillar Theme Component",
          key: :theme,
          path: "theme",
          component_class: "Pillar::Theme",
          mount: true
        )

        Pillar::Core.register(component)
      end
    end
  end
end
