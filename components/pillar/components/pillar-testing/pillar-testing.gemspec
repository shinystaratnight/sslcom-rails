# frozen_string_literal: true

$:.push File.expand_path("lib", __dir__)

require "pillar/testing/version"

rails_version = File.read(File.join(__dir__, "../../.rails-version"))

Gem::Specification.new do |s|
  s.name = "pillar-testing"
  s.version = Pillar::Testing::VERSION
  s.authors = ["Dustin Ward"]
  s.email = "dustin.n.ward@gmail.com"
  s.homepage = ""
  s.summary = "Pillar testing"
  s.description = "Component based rails applications mad easy."

  s.files = Dir["{config,lib}/**/*", "Rakefile", "README.md"]
  s.require_paths = ["lib"]

  ##
  ## GENERAL
  ##

  s.add_dependency "combustion"
  s.add_dependency "rails", rails_version

  ##
  ## RSPEC & CAPYBARA
  ##

  s.add_dependency "capybara"
  s.add_dependency "capybara-screenshot"
  s.add_dependency "rspec-rails"
  s.add_dependency "shoulda-matchers"
  s.add_dependency "webdrivers"

  ##
  ## LINTING
  ##

  s.add_dependency "rubocop"
  s.add_dependency "rubocop-performance"
  s.add_dependency "rubocop-rails"
  s.add_dependency "rubocop-rspec"
  s.add_dependency "standard"

  ##
  ## TOOLS
  ##

  s.add_dependency "annotate"
  s.add_dependency "brakeman"
  s.add_dependency "database_cleaner"
  s.add_dependency "factory_bot_rails"
  s.add_dependency "faker"
  s.add_dependency "puma"
  s.add_dependency "timecop"

  ##
  ## COVERAGE
  ##

  s.add_dependency "simplecov"
  s.add_dependency "simplecov-console"
  s.add_dependency "simplecov-material"
  s.add_dependency "simplecov-shields-badge"

  ##
  ## Formatters
  ## Progressbar-like formatter for RSpec
  ##

  s.add_dependency "fuubar"
  s.add_dependency "rspec-instafail"
  s.add_dependency "rspec_junit_formatter"

  s.add_development_dependency "pry"
end
