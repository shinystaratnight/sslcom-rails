require "net/https"
require "uri"

class Surl < ActiveRecord::Base
  belongs_to :user

  validate :url_format

  if Rails.env=='development'
    URL = 'staging1.ssl.com:3000'
  else
    URL = 'staging1.ssl.com'
  end

  after_initialize :default_values

  after_create do |s|
    s.update_attribute :identifier, s.id.to_s(36)
  end

  def is_http?
    original =~ /^http/
  end

  end

  private
  def default_values
    self.share = true
    self.require_ssl = false
  end

  def url_format
    errors.add :original,
      "is an invalid url. Please be sure it begins with http://, https://, or ftp://" unless
      [URI::HTTP, URI::HTTPS, URI::FTP].find do |url_type|
        URI.parse(original).kind_of?(url_type)
      end
  rescue
  end
end
