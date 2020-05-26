$:.push File.expand_path("lib", __dir__)

require "pillar/authentication/version"

rails_version = File.read(File.join(__dir__, "../../.rails-version"))

Gem::Specification.new do |s|
  s.name        = "pillar-authentication"
  s.version     = Pillar::Authentication::VERSION
  s.authors     = ["Dustin Ward"]
  s.email       = "dustin.n.ward@gmail.com"
  s.homepage    = ""
  s.summary     = "Pillar authentication"
  s.description = "Component based rails applications mad easy."

  s.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]
  s.require_paths = ["lib"]

  s.add_dependency "pillar-core"
  s.add_dependency "pillar-theme"

  s.add_dependency "rails", rails_version
  s.add_dependency "mysql2"

  # s.add_dependency "acts_as_tenant"
  # s.add_dependency "devise"
  # s.add_dependency "devise_invitable"
  # s.add_dependency "devise_masquerade"

  s.add_development_dependency "pillar-testing"
end
