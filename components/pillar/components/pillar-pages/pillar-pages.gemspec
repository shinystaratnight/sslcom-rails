# frozen_string_literal: true

$:.push File.expand_path("lib", __dir__)

require "pillar/pages/version"

rails_version = File.read(File.join(__dir__, "../../.rails-version"))

Gem::Specification.new do |s|
  s.name = "pillar-pages"
  s.version = Pillar::Pages::VERSION
  s.authors = ["Dustin Ward"]
  s.email = "dustin.n.ward@gmail.com"
  s.homepage = ""
  s.summary = "Pillar pages"
  s.description = "Component based rails applications mad easy."

  s.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]
  s.require_paths = ["lib"]

  s.add_dependency "pillar-core"
  s.add_dependency "pillar-theme"

  s.add_dependency "mysql2"
  s.add_dependency "rails", rails_version

  s.add_development_dependency "pillar-testing"
end
