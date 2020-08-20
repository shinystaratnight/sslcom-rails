class Sandbox < Website
  def self.exists?(domain = '')
    return false if domain.blank?

    Rails.cache.fetch("Sandbox.exists/#{domain}", expires_in: 24.hours) do
      where{ (host == domain) | (api_host == domain) }.present?
    end
  end
end
