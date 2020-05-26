module Pillar
  class Engine < ::Rails::Engine
    isolate_namespace Pillar

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
  end
end
