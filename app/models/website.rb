class Website

  attr_accessor :database_name

  def self.find_by_subdomain(subdomain)
    @website=Website.new
    @website.database_name="sandbox_ssl_com" #subdomain
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