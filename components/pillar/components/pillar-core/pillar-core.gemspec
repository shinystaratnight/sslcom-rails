# frozen_string_literal: true

$:.push File.expand_path("lib", __dir__)

require "pillar/core/version"

rails_version = File.read(File.join(__dir__, "../../.rails-version"))

Gem::Specification.new do |s|
  s.name = "pillar-core"
  s.version = Pillar::Core::VERSION
  s.authors = ["Dustin Ward"]
  s.email = "dustin.n.ward@gmail.com"
  s.homepage = ""
  s.summary = "Pillar core"
  s.description = "Component based rails applications mad easy."

  s.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]
  s.require_paths = ["lib"]

  s.add_dependency "pillar"

  s.add_dependency "groupdate"
  s.add_dependency "haml-rails"
  s.add_dependency "mysql2"
  s.add_dependency "pagy"
  s.add_dependency "pry"
  s.add_dependency "rails", rails_version
  s.add_dependency "ransack"
  s.add_dependency "responders"

  s.add_development_dependency "pillar-testing"
end
