require 'net/http'
require 'uri'

class Callback < ActiveRecord::Base
  belongs_to  :callbackable, polymorphic: true

  AUTH = {basic: 'basic'}
  METHODS = {get: 'get', post: 'post'}

  validates   :url, presence: true, format: /\Ahttps:\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i
  validates   :method, inclusion:
      {in: METHODS.values, message: "needs to be one of the following: #{METHODS.values.join(', ')}"}
  validates   :auth, inclusion:
      {in: AUTH.values, message: "needs to be one of the following: #{AUTH.values.join(', ')}"}
  validate   :basic_auth_validation, if: lambda {|cb|cb.auth==AUTH[:basic]}
  serialize  :parameters

  before_validation {
    self.auth = self.auth.downcase
    self.method = self.method.downcase
  }

  after_initialize do
    if new_record?
      self.method ||= METHODS[:get]
    end
  end

  def basic_auth_validation
    unless !parameters.blank? && parameters[:username] && parameters[:password]
      errors.add(:parameters, "must have username and password for basic auth")
    end
  end

  def perform_callback(options={})
    uri = URI.parse(self.url)
    req = method==METHODS[:post] ? Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json') :
              Net::HTTP::Get.new(uri)
    req.basic_auth parameters[:username], parameters[:password] if auth
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    # req.body = parameters.reject{|p|[:username,:password].include? p}
    res = http.request(req)
    return req, res
  end
end
