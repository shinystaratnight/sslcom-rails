class DomainConstraint
  def initialize(domain)
    @domains = [domain].flatten
  end

  def matches?(request)
      return true if (Rails.env.test? || Rails.env.development?)
      return @domains.include?(request.host) if Rails.env.production?
  end
end