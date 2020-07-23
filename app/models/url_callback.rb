# == Schema Information
#
# Table name: url_callbacks
#
#  id                :integer          not null, primary key
#  auth              :text(65535)
#  callbackable_type :string(255)
#  headers           :text(65535)
#  method            :string(255)
#  parameters        :text(65535)
#  url               :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  callbackable_id   :integer
#
# Indexes
#
#  index_url_callbacks_on_callbackable_id_and_callbackable_type  (callbackable_id,callbackable_type)
#

require 'net/http'
require 'uri'

class UrlCallback < ApplicationRecord
  belongs_to  :callbackable, polymorphic: true

  AUTH = {basic: 'basic'}
  METHODS = {get: 'get', post: 'post'}

  validates   :url, presence: true, format: /\Ahttps?:\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i
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
    UrlCallback.perform_callback(self,options)
  end

  def self.perform_callback(url_callback, options)
    begin
      uri = URI.parse(url_callback.url)
      req = url_callback.method == METHODS[:post] ? Net::HTTP::Post.new(uri, 'Content-Type' =>
        (url_callback.headers and url_callback.headers["content-type"]) ?
            url_callback.headers["content-type"] : 'application/json') : Net::HTTP::Get.new(uri)
      req.basic_auth url_callback.auth["basic"]["username"],
                     url_callback.auth["basic"]["password"] if (url_callback.auth and url_callback.auth["basic"])
      http = Net::HTTP.new(uri.host, uri.port)
      if url_callback.url =~ /^https/i
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      req.body =
        if url_callback.parameters['certificate_hook']
          cert_param = url_callback.parameters['certificate_hook'] || "certificate_hook"
          url_callback.parameters.delete('certificate_hook')
          url_callback.parameters.merge(cert_param=>eval(options[:certificate_hook].gsub!("null","nil")))
        else
          url_callback.parameters.merge(certificate_hook: eval(options[:certificate_hook].gsub!("null","nil")))
        end.to_json
      res = http.request(req)
      if res.code == "301"
        res = Net::HTTP.get_response_with_redirect(URI.parse(res.header['location']))
      end
      return req, res
    rescue Exception => e
      audit = SystemAudit.create(owner: url_callback, target: url_callback.callbackable,
                         notes: "failed callback: #{e.message}",
                         action: "UrlCallback#perform_callback")
      OrderNotifier.problem(audit).deliver
      return false
    end
  end
end
