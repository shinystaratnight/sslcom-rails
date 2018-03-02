require 'net/http'
require 'uri'

class UrlCallback < ActiveRecord::Base
  belongs_to  :callbackable, polymorphic: true

  AUTH = {basic: 'basic'}
  METHODS = {get: 'get', post: 'post'}

  validates   :url, presence: true, format: /\Ahttps:\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i
  validates   :method, inclusion:
      {in: METHODS.values, message: "needs to be one of the following: #{METHODS.values.join(', ')}"}
  # validates   :auth, inclusion:
  #     {in: AUTH.values, message: "needs to be one of the following: #{AUTH.values.join(', ')}"}
  validate    :auth_validation, if: lambda {|cb|cb.auth}
  serialize   :parameters
  serialize   :headers
  serialize   :auth


  before_validation {
    # self.auth = self.auth.downcase
    self.method = self.method.downcase
  }

  after_initialize do
    if new_record?
      self.method ||= METHODS[:get]
    end
  end

  def auth_validation
    unless auth.is_a?(Hash)
      errors[:auth] << "expecting hash"
      return false
    end
    errors.add(:auth, "needs to be one of the following: #{AUTH.values.join(', ')}") unless AUTH.values.include?(self.auth.keys.last)
    if auth[:basic]
      errors.add("auth.basic".to_sym, "must have username for basic auth") unless auth[:basic].keys.include? 'username'
      errors.add("auth.basic".to_sym, "must have password for basic auth") unless auth[:basic].keys.include? 'password'
    end
  end

  def perform_callback(options={})
    begin
      uri = URI.parse(self.url)
      req = method==METHODS[:post] ? Net::HTTP::Post.new(uri, 'Content-Type' =>
        (headers and headers["content-type"]) ? headers["content-type"] : 'application/json') : Net::HTTP::Get.new(uri)
      req.basic_auth auth["basic"]["username"], auth["basic"]["username"] if (auth and auth["basic"])
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      req.body = if parameters['certificate_hook']
        cert_param = parameters['certificate_hook'] || "certificate_hook"
        parameters.delete('certificate_hook')
        parameters.merge(cert_param=>options[:certificate_hook])
      else
        parameters.merge(certificate_hook: options[:certificate_hook])
      end.to_json
      res = http.request(req)
      return req, res
    rescue Exception=>e
      return false
    end
  end
end
