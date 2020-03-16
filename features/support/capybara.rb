# frozen_string_literal: true

require 'capybara'
require 'capybara/rails'
require 'capybara/cucumber'
require 'capybara/session'
require 'selenium-webdriver'

Capybara.javascript_driver = :webkit

# require 'factory_bot/step_definitions'

Capybara.app_host = "http://#{Settings.dev_portal_domain}:3000"

module Capybara
  def is_capybara?
    respond_to? :After
  end
end

World(Capybara)
