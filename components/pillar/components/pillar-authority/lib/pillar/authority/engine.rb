require "rails/engine"

module Pillar
  module Authority 
    class Engine < ::Rails::Engine
      isolate_namespace Pillar::Authority

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

      config.after_initialize do
        menu = []

        menu.push(
          Pillar::Core::MenuItem.new(
            title: "Blocklist Entries",
            path: "admin_blocklist_entries_path",
            group: :administration,
            order: 2,
          )
        )

        component = Pillar::Core::Component.new(
          name: "Authority",
          description: "Pillar Authority Component",
          key: :authority,
          path: "authority",
          component_class: "Pillar::Authority",
          mount: true,
          menu: menu
        )

        Pillar::Core.register(component)
      end
    end
  end
end
