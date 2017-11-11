# This allows a reseller to white-label the RA portal. It allows for optional seperate db
class Website < ActiveRecord::Base
  belongs_to :db

  attr_accessor :database_name

  def self.sandbox_db(domain=nil)
    if domain and @website=Website.find_by_host(domain)
      @website.database_name=@website.db.name
    else
      @website=Website.new
      @website.database_name=get_database_name
    end
    @website
  end

  def use_database
    ActiveRecord::Base.establish_connection(website_connection)
  end

# Revert back to the shared database
  def revert_database
    ActiveRecord::Base.establish_connection(default_connection)
  end

  private
  
  def self.get_database_name
    target_db = ENV.fetch('SANDBOX_DATABASE') if ENV['SANDBOX_DATABASE'].present?
    target_db || 'sandbox_ssl_com'
  end

# Regular database.yml configuration hash
  def default_connection
    @default_config ||= ActiveRecord::Base.connection.instance_variable_get("@config").dup
  end

# Return regular connection hash but with database name changed
# The database name is a attribute (column in the database)
  def website_connection
    default_connection.dup.update(database: self.database_name)
  end
end