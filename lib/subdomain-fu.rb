module SubdomainFu

  def self.host_without_subdomain(host)
    host = "ssl.com" if host=="ssl"
    parts = host.split('.')
    #Rails.logger.info "host = #{host}" if parts[-(SubdomainFu.config.tld_size+1)..-1].blank?
    parts[-(SubdomainFu.config.tld_size+1)..-1].join(".")
  end

end