class ComponentGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  def create_engine_file
    directory(".", "components/pillar-#{name}")

    chmod "components/pillar-#{name}/bin/console", 0o755, verbose: false
    chmod "components/pillar-#{name}/bin/rails", 0o755, verbose: false
  end
end
