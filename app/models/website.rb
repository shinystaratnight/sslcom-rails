class Website < ApplicationRecord
  belongs_to :db

  def self.domain_contraints
    Rails.cache.fetch("domain_contraints",expires_in: 24.hours){Website.pluck(:api_host)+Sandbox.pluck(:host)}
  end

  def self.current_site(domain)
    cs_id=Rails.cache.fetch("current_site/#{domain}",
                      expires_in: 24.hours) {
        cs=self.where{(host == domain) | (api_host == domain)}.last
        cs ? cs.id : ''}
    Website.find cs_id unless cs_id.blank?
  end

  def use_database
    ApplicationRecord.establish_connection(website_connection)
    CertificateContent.cli_domain=self.api_host unless self.api_host.blank?
  end

# Revert back to the shared database
  def self.revert_database
    ApplicationRecord.establish_connection(Website::default_connection)
  end

  # production api
  def api_domain
    Rails.cache.fetch("api_domain/#{cache_key}") {api_host}
  end

  # production test api
  def test_api_domain
    Rails.cache.fetch("test_api_domain/#{cache_key}") {api_host}
  end

  # development api
  def dev_api_domain
    Rails.cache.fetch("dev_api_domain/#{cache_key}") {api_host}
  end

  #development text api
  def dev_test_api_domain
    Rails.cache.fetch("dev_test_api_domain/#{cache_key}") {api_host}
  end

  private
  
# Regular database.yml configuration hash
  def self.default_connection
    @default_config ||= ApplicationRecord.connection.instance_variable_get("@config").dup
  end

# Return regular connection hash but with database name changed
# The database name is a attribute (column in the database)
  def website_connection
    Website::default_connection.dup.update(database: self.db.name)
  end
end
