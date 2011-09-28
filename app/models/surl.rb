require "net/https"
require "uri"
require "digest/sha1"

class Surl < ActiveRecord::Base
  belongs_to  :user
  has_many    :surl_visits

  validate  :url_format
  validates :guid, uniqueness: true, on: :create
  validates :username, length: {within: 6..16}, presence: true, :if => :perform_username_validation?
  validates :password, length: {within: 6..16}, presence: true, :if => :perform_password_validation?

  attr_accessor :password
  attr_accessor_with_default :set_access_restrictions, "0"

  REDIRECTED="redirect"
  RENDERED="render"
  BLACKLISTED="blacklisted"
  LOOP_ERROR="Trying to confuse us? Sorry, but ssl links pointing to ssl.com are not allowed,
    otherwise we'll loop forever."
  SUBDOMAIN="links"
  TIMEOUT_DURATION=1
  RETRIES=2
  DISABLED_STATUS="disabled"

  REMOVE="remove"

  if Rails.env=='development'
    URL = 'www.ssl.com:3000'
  else
    URL = 'www.ssl.com'
  end

#  before_create
  before_save       :tasks_on_save
  after_initialize  :default_values#, :prep
  after_create do |s|
    s.update_attributes identifier: s.id.encode62
  end

  default_scope where(:status ^ DISABLED_STATUS).order(:created_at.desc)

  def access_granted(surl)
    username==surl.username && valid_password?(surl.password)
  end

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
    if new_record?
      self.share = true
      self.require_ssl = false
      self.guid=UUIDTools::UUID.random_create.to_s
    end
    prep
  end

  def prep
    unless username.blank? && password.blank?
      self.set_access_restrictions="1"
    else
      self.username, self.password = [nil,nil]
    end
  end

  def tasks_on_save
    if(perform_password_validation?)
      hash_password
    elsif(set_access_restrictions=="0")
      self.username, self.password, self.password_hash, self.password_salt = [nil,nil,nil,nil]
    end
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

  # Assert whether or not the password validations should be performed. Always on new records, only on existing
  # records if the .password attribute isn't blank.
  def perform_password_validation?
    set_access_restrictions=="1" && (new_record? ? true : !(password.blank? && !password_hash.blank?))
  end

  def perform_username_validation?
    set_access_restrictions=="1"
  end
end
