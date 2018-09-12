class Sandbox < Website
  def self.exists?(domain)
    Rails.cache.fetch("Sandbox.exists/#{domain}", expires_in: 24.hours) {
      !self.where{(host == domain) | (api_host == domain)}.blank?
    }
  end
end
