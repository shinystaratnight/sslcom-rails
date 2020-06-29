$:.push File.expand_path("lib", __dir__)

require "pillar/authority/version"

rails_version = File.read(File.join(__dir__, "../../.rails-version"))

Gem::Specification.new do |s|
  s.name        = "pillar-authority"
  s.version     = Pillar::Authority::VERSION
  s.authors     = ["Dustin Ward"]
  s.email       = "dustin.n.ward@gmail.com"
  s.homepage    = ""
  s.summary     = "Pillar authority"
  s.description = "Component based rails applications mad easy."

  s.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]
  s.require_paths = ["lib"]

  s.add_dependency "pillar-core"
  s.add_dependency "pillar-authentication"
  s.add_dependency "pillar-theme"

  s.add_dependency "mysql2"
  s.add_dependency "rails", rails_version
  s.add_dependency "rails_or"
end
