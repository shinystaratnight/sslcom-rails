# app/constraints/api_constraint.rb
class APIConstraint
  attr_reader :version
  
  DEFAULT_API_VERSION = 1

  def initialize(options)
    @version = options.fetch(:version)
  end

  def matches?(request)
    set_default_api_version(request) unless api_version_specified?(request)
    request.headers.fetch(:accept).include?("version=#{version}")
  end
  
  private
  
  def set_default_api_version(request)
    request.headers[:accept] = request.headers.fetch(:accept)
      .concat(";version=#{DEFAULT_API_VERSION}")
  end
  
  def api_version_specified?(request)
    request.headers.fetch(:accept).include?('version')
  end
end
