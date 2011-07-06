require "net/https"
require "uri"
require "digest/sha1"

class Surl < ActiveRecord::Base
  belongs_to :user
  has_many    :surl_visits

  validate :url_format
  validates :identifier, uniqueness: true
  validates :guid, uniqueness: true
  validates :username, length: {within: 6..16}, presence: true, :if => :perform_password_validation?
  validates :password, length: {within: 6..16}, presence: true, :if => :perform_password_validation?

  attr_accessor :password
  attr_accessor_with_default :set_access_restrictions, false

  REDIRECTED="redirect"
  RENDERED="render"
  BLACKLISTED="blacklisted"
  LOOP_ERROR="Trying to confuse us? Sorry, but ssl links pointing to ssl.com are not allowed,
    otherwise we'll loop forever."
  SUBDOMAIN="links"

  REMOVE="remove"

  if Rails.env=='development'
    URL = 'staging1.ssl.com:3000'
  else
    URL = 'staging1.ssl.com'
  end

  before_save   :hash_password
  after_initialize :default_values
  after_create do |s|
    s.update_attributes identifier: s.id.encode62, guid: UUIDTools::UUID.random_create.to_s
  end

  default_scope order(:created_at.desc)

  # Returns true if the password passed matches the password in the DB
  def valid_password?(password)
    self.password_hash == self.class.hash_password(password, self.password_salt)
  end

  def is_http?
    original =~ /^http/
  end

  def to_param
    guid
  end

  def full_link
    "http#{'s' if require_ssl}://ssl.com/#{identifier}"
  end

  private
  def default_values
    self.share = true
    self.require_ssl = false
  end

  #validation method to make sure the submitted url is http, https, or ftp
  def url_format
    unless [URI::HTTP, URI::HTTPS, URI::FTP].find {|url_type| URI.parse(original).kind_of?(url_type)}
      errors.add :original, "is an invalid url. Please be sure it begins with http://, https://, or ftp://"
    else
      errors.add(:original, Surl::LOOP_ERROR) if URI.parse(original).host.downcase =~ /ssl.com/
    end
  rescue Exception=>e
    logger.error("Error in Surl#url_format: #{e.message}")
  end

  # Performs the actual password encryption. You want to change this salt to something else.
  def self.hash_password(password, salt)
    Digest::SHA1.hexdigest(password, salt)
  end

  # Sets the hashed version of self.password to password_hash, unless it's blank.
  def hash_password
    self.password_salt=ActiveSupport::SecureRandom.base64(8)
    self.password_hash = self.class.hash_password(self.password,self.password_salt) unless self.password.blank?
  end

  # Assert wether or not the password validations should be performed. Always on new records, only on existing
  # records if the .password attribute isn't blank.
  def perform_password_validation?
    not set_access_restrictions=="0"
  end
end
