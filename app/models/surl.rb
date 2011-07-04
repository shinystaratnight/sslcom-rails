require "net/https"
require "uri"

class Surl < ActiveRecord::Base
  belongs_to :user

  validate :url_format
  validates :identifier, uniqueness: true
  validates :guid, uniqueness: true

  REMOVE="remove"

  if Rails.env=='development'
    URL = 'staging1.ssl.com:3000'
  else
    URL = 'staging1.ssl.com'
  end

  after_initialize :default_values

  after_create do |s|
    s.update_attributes identifier: s.id.encode62, guid: UUIDTools::UUID.random_create
  end

  def is_http?
    original =~ /^http/
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
