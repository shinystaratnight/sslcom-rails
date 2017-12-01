class Sandbox < Website
  def self.exists?(domain)
    !self.where{(host == domain) | (api_host == domain)}.blank?
  end
end
