$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "pillar/version"

rails_version = File.read(File.join(__dir__, ".rails-version"))

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "pillar"
  spec.version     = Pillar::VERSION
  spec.authors     = ["Dustin Ward"]
  spec.email       = ["dustin.n.ward@gmail.com"]
  spec.homepage    = "https://www.ssl.com"
  spec.summary     = "Pillar - Component Based Rails"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", rails_version
  spec.add_dependency "mysql2"
end
