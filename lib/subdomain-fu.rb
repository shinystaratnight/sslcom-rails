module SubdomainFu

  def self.host_without_subdomain(host)
    parts = host.split('.')
    Rails.logger.error "host = #{host}" if parts[-(SubdomainFu.config.tld_size+1)..-1].blank?
    parts[-(SubdomainFu.config.tld_size+1)..-1].join(".")
  end

end