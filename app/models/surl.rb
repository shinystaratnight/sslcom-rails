# == Schema Information
#
# Table name: surls
#
#  id            :integer          not null, primary key
#  guid          :string(255)
#  identifier    :string(255)
#  original      :text(65535)
#  password_hash :string(255)
#  password_salt :string(255)
#  require_ssl   :boolean
#  share         :boolean
#  status        :string(255)
#  username      :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#  user_id       :integer
#
# Indexes
#
#  index_surls_on_user_id  (user_id)
#

require 'net/https'
require 'uri'
require 'digest/sha1'

class Surl < ApplicationRecord
  belongs_to  :user
  has_many    :surl_visits

  validate  :url_format
  validates :guid, uniqueness: true, on: :create
  validates :username, length: { within: 6..50 }, presence: true, if: :perform_username_validation?
  validates :password, length: { within: 6..20 }, presence: true, if: :perform_password_validation?

  attr_accessor :password
  attr_accessor :set_access_restrictions

  REDIRECTED = 'redirect'
  RENDERED = 'render'
  BLACKLISTED = 'blacklisted'
  LOOP_ERROR = "Trying to confuse us? Sorry, but ssl links pointing to ssl.com are not allowed,
    otherwise we'll loop forever."
  SUBDOMAIN = 'links'
  TIMEOUT_DURATION = 10
  # TIMEOUT_CAA_CHECK_DURATION=30
  RETRIES = 2
  COOKIE_VERSION = 1
  COOKIE_NAME = :links2
  DISABLED_STATUS = 'disabled'
  REDIRECT_FILES = %w[ACE AIF ANI API ART AVI BIN BMP BUD BZ2 CAT CBT CDA CDT CHM CLP CMD CMF CUR DAO
                      DAT DD DEB DEV DIR DLL DOC DOT DRV DS DWG DXF EMF EML EPS EPS2 EXE FFL FFO FLA FNT GIF GID GRP
                      GZ HEX HLP HT HQX ICL ICM ICO JAR JPEG JPG LAB LGO LIT LOG LSP MAQ MAR MDB MDL MID MOD MOV MP3 MP4
                      MPEG MPP MSG MSG NCF NLM O OCX ODT OGG OST PAK PCL PCT PDF PDR PIF PL PM3 PM4 PM5 PM6 PNG POL POT
                      PPD PPS PPT PRN PS PSD PSP PST PUB PWL QIF QT RAM RAR RAW RDO REG RM RPM RSC RTF SCR SEA SGML SH
                      SIT SMD SVG SWF SWP SYS TAR TGA TIFF TIF TMP TTF TXT UDF UUE VBX VM VXD WAV WMF WRI WSZ XCF XIF
                      XIF XIF XLS XLT XML XSL ZIP].freeze

  REMOVE = 'remove'

  URL = if Rails.env.development?
          "#{I18n.t('labels.ssl_ca')}:3000"
        else
          I18n.t('labels.ssl_ca')
        end

  # before_create
  before_save       :tasks_on_save
  after_initialize  :default_values # , :prep
  after_create do |s|
    s.update_attributes identifier: s.id.encode62
  end

  default_scope{ where{ status >> [nil, DISABLED_STATUS] }.order(:created_at.desc) }

  def access_granted(surl)
    username == surl.username && valid_password?(surl.password)
  end

  # Returns true if the password passed matches the password in the DB
  def valid_password?(password)
    password_hash == self.class.hash_password(password, password_salt)
  end

  def is_http?
    original =~ /\Ahttp/
  end

  def to_param
    guid
  end

  def full_link
    "http#{'s' if require_ssl}://ssl.com/#{identifier}"
  end

  def uri
    original.delete(' ')
  end

  private

  def default_values
    if new_record?
      self.share ||= false
      self.require_ssl ||= false
      self.guid ||= UUIDTools::UUID.random_create.to_s
      self.set_access_restrictions ||= '0'
    end
    prep
  end

  def prep
    if username.blank? && password.blank?
      self.username = nil
      self.password = nil
    else
      self.set_access_restrictions = '1'
    end
  end

  def tasks_on_save
    if perform_password_validation?
      hash_password
    elsif set_access_restrictions == '0'
      self.username = nil
      self.password = nil
      self.password_hash = nil
      self.password_salt = nil
    end
  end

  # validation method to make sure the submitted url is http, https, or ftp
  def url_format
    unless [URI::HTTP, URI::HTTPS, URI::FTP].find {|url_type| URI.parse(original).kind_of?(url_type)}
      errors.add :original, 'is an invalid url. Please be sure it begins with http://, https://, or ftp://'
    else
      errors.add(:original, Surl::LOOP_ERROR) if URI.parse(original).host =~ /\Assl.com\z/i
    end
  rescue StandardError => e
    logger.error("Error in Surl#url_format: #{e.message}")
  end

  # Performs the actual password encryption. You want to change this salt to something else.
  def self.hash_password(password, salt)
    Digest::SHA1.hexdigest(password + salt)
  end

  # Sets the hashed version of self.password to password_hash, unless it's blank.
  def hash_password
    self.password_salt = SecureRandom.base64(8)
    self.password_hash = self.class.hash_password(password, password_salt) unless password.blank?
  end

  # Assert whether or not the password validations should be performed. Always on new records, only on existing
  # records if the .password attribute isn't blank.
  def perform_password_validation?
    set_access_restrictions == '1' && (new_record? ? true : !(password.blank? && !password_hash.blank?))
  end

  def perform_username_validation?
    set_access_restrictions == '1'
  end
end
