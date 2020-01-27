# == Schema Information
#
# Table name: csrs
#
#  id                        :integer          not null, primary key
#  certificate_content_id    :integer
#  body                      :text(65535)
#  duration                  :integer
#  common_name               :string(255)
#  organization              :string(255)
#  organization_unit         :string(255)
#  state                     :string(255)
#  locality                  :string(255)
#  country                   :string(255)
#  email                     :string(255)
#  sig_alg                   :string(255)
#  created_at                :datetime
#  updated_at                :datetime
#  subject_alternative_names :text(65535)
#  strength                  :integer
#  challenge_password        :boolean
#  certificate_lookup_id     :integer
#  decoded                   :text(65535)
#  ext_customer_ref          :string(255)
#  public_key_sha1           :string(255)
#  public_key_sha256         :string(255)
#  public_key_md5            :string(255)
#  ssl_account_id            :integer
#  ref                       :string(255)
#  friendly_name             :string(255)
#  modulus                   :text(65535)
#

require 'zip/zip'
require 'zip/zipfilesystem'
require 'openssl-extensions/all'
require 'digest'
require 'net/https'
require 'uri'

class Csr < ApplicationRecord
  extend Memoist
  include Encodable
  
  has_many    :whois_lookups, :dependent => :destroy
  has_many    :signed_certificates, -> { where(type: nil) }, :dependent => :destroy
  has_one :signed_certificate, -> { where(type: nil).order 'created_at' }, class_name: "SignedCertificate"
  has_many    :shadow_certificates
  has_many    :ca_certificate_requests, as: :api_requestable, dependent: :destroy
  has_many    :sslcom_ca_requests, as: :api_requestable
  has_many    :ca_api_requests, as: :api_requestable
  has_many    :ca_dcv_requests, as: :api_requestable, dependent: :destroy
  has_many    :ca_dcv_resend_requests, as: :api_requestable, dependent: :destroy
  has_many    :domain_control_validations, :dependent => :destroy do
    def last_sent
      where{email_address !~ 'null'}.last
    end

    def last_emailed
      where{(email_address !~ 'null') & (dcv_method >> [nil,'email'])}.last
    end

    def last_method
      where{dcv_method >> ['http','https','email']}.last
    end
  end
  has_many    :csr_unique_values, :dependent => :destroy
  has_one     :csr_override  #used for overriding csr fields - does not include a full csr
  belongs_to  :certificate_content, touch: true
  belongs_to  :certificate_lookup
  belongs_to  :ssl_account, touch: true
  has_one    :certificate_order, :through=>:certificate_content
  has_many    :certificate_orders, :through=>:certificate_content # api_requestable.certificate_orders compatibility
  serialize   :subject_alternative_names
  validates_presence_of :body
  # validates_presence_of :common_name, :if=> "!body.blank?", :message=> "field blank. Invalid csr."
  # validates_uniqueness_of :unique_value, scope: :public_key_sha1

  #will_paginate
  cattr_accessor :per_page
  @@per_page = 10

  scope :sslcom, ->{joins{certificate_content}.where.not certificate_contents: {ca_id: nil}}

  scope :search, lambda { |term|
    where("MATCH (common_name, body, decoded) AGAINST ('#{term}')")
  }

  scope :pending, ->{joins(:certificate_content).
      where{certificate_contents.workflow_state >> ['pending_validation', 'validated']}.
      order("certificate_contents.updated_at asc")}

  scope :range, lambda{|start, finish|
    if start.is_a? String
      s= start =~ /\// ? "%m/%d/%Y" : "%m-%d-%Y"
      f= finish =~ /\// ? "%m/%d/%Y" : "%m-%d-%Y"
      start = Date.strptime start, s
      finish = Date.strptime finish, f
    end
    where{updated_at >> (start..finish)}} do
  end

  BEGIN_TAG="-----BEGIN CERTIFICATE REQUEST-----"
  END_TAG="-----END CERTIFICATE REQUEST-----"
  BEGIN_NEW_TAG="-----BEGIN NEW CERTIFICATE REQUEST-----"
  END_NEW_TAG="-----END NEW CERTIFICATE REQUEST-----"

  COMMAND=->(key_file){%x"openssl rsa -pubin -in #{key_file} -text -noout"}
  TIMEOUT_DURATION=10

  before_create do |csr|
    csr.ref = generate_ref
  end

  after_create do |c|
    tmp_file = "#{Rails.root}/tmp/csr_pub-#{DateTime.now.to_i}.key"
    File.open(tmp_file, 'wb') do |f|
      f.write c.public_key
    end
    modulus = Timeout.timeout(TIMEOUT_DURATION) do
      COMMAND.call tmp_file
    end
    c.update_column(:modulus, modulus)
    File.delete(tmp_file) if File.exist?(tmp_file)
  end

  after_save do |c|
    c.certificate_content.touch unless c.certificate_content.blank?
    c.certificate_order.touch unless c.certificate_content.blank?

  end

  # def to_param
  #   ref
  # end

  def unique_value
    if certificate_content.blank? or certificate_content.ca.blank?
      csr_unique_value.unique_value
    else
      if ca_certificate_requests.first and !ca_certificate_requests.first.unique_value.blank?
        ca_certificate_requests.first.unique_value # comodo has returned a unique already
      else
        if csr_unique_values.empty?
          if new_record?
            csr_unique_values.build(unique_value: SecureRandom.hex(5)) # generate our own
          else
            csr_unique_values.create(unique_value: SecureRandom.hex(5)) # generate our own
          end
        end
        csr_unique_values.last.unique_value
      end
    end
  end
  memoize :unique_value

  def csr_unique_value
    last_unique_value = csr_unique_values.last
    #if unique_value is expired, then new unique_value should be generated
    if last_unique_value.nil? or (Date.today-last_unique_value.created_at.to_date).to_i > 30
      last_unique_value = new_record? ?
                              csr_unique_values.build(unique_value: SecureRandom.hex(5)) :
                              csr_unique_values.create(unique_value: SecureRandom.hex(5))
    end
    last_unique_value
  end
  memoize :csr_unique_value

  def common_name_to_unicode
    SimpleIDN.to_unicode(read_attribute(:common_name)).gsub(/\x00/, '') unless read_attribute(:common_name).blank?
  end

  def body=(csr)
    csr=Csr.enclose_with_tags(csr.strip)
    unless Settings.csr_parser=="remote"
      self[:body] = csr
      begin
        parsed = OpenSSL::X509::Request.new csr
      rescue
        location = "CertificateContent.id=#{certificate_content.id}=>" if
          certificate_content
        location +="Csr.id=#{id}=>" unless id.blank?
        logger.error "could not parse #{location || 'unknown'} for #{csr}"
        errors.add :base, 'error: could not parse csr'
      else
        self[:common_name] = parsed.subject.common_name
        self[:organization] = force_string_encoding(parsed.subject.organization)
        self[:organization_unit] = force_string_encoding(parsed.subject.organizational_unit)
        self[:state] = force_string_encoding(parsed.subject.region)
        self[:locality] = force_string_encoding(parsed.subject.locality)
        self[:country] = force_string_encoding(parsed.subject.country)
        self[:email] = parsed.subject.email
        self[:sig_alg] = parsed.signature_algorithm
        self[:subject_alternative_names] = parsed.subject_alternative_names
        begin
          self[:strength] = parsed.strength
          self[:challenge_password] = parsed.challenge_password?
        rescue
        end
      end
    else
      ssl_util = Savon::Client.new Settings.csr_parser_wsdl
      self[:body] = csr
      begin
        response = ssl_util.parse_csr do |soap|
          soap.body = {:csr => csr}
        end
      rescue
        location = "CertificateContent.id=#{certificate_content.id}=>" if
          certificate_content
        location +="Csr.id=#{id}=>" unless id.blank?
          certificate_content
        logger.error "could not parse #{location || 'unknown'} for #{csr}"
      else
        parsed = response.to_hash[:multi_ref]
        self[:duration] = parsed[:duration] unless parsed[:duration].is_a? Hash
        self[:common_name] = parsed[:common_name] unless parsed[:common_name].is_a? Hash
        self[:organization] = parsed[:organization] unless parsed[:organization].is_a? Hash
        self[:organization_unit] = parsed[:organization_unit] unless parsed[:organization_unit].is_a? Hash
        self[:state] = parsed[:state] unless parsed[:state].is_a? Hash
        self[:locality] = parsed[:locality] unless parsed[:locality].is_a? Hash
        self[:country] = parsed[:country] unless parsed[:country].is_a? Hash
        self[:email] = parsed[:email] unless parsed[:email].is_a? Hash
        self[:sig_alg] = parsed[:sig_alg] unless parsed[:sig_alg].is_a? Hash
      end
    end
  end

  def self.remove_begin_end_tags(csr)
    csr.gsub!(/-+BEGIN.+?REQUEST-+/,"") if csr =~ /-+BEGIN.+?REQUEST-+/
    csr.gsub!(/-+END.+?REQUEST-+/,"") if csr =~ /-+END.+?REQUEST-+/
    csr
  end

  def sslcom_approval_ids
    sslcom_ca_requests.unexpired.pluck(:approval_id)
  end

  def sslcom_usernames
    sslcom_ca_requests.unexpired.pluck(:username)
  end

  def sslcom_outstanding_approvals
    status=SslcomCaApi.get_status(csr: self, mapping: certificate_content.ca)[1].body
    if status=="[]" or status.blank?
      0
    else
      JSON.parse(status)
    end
  end

  def self.enclose_with_tags(csr)
    csr=remove_begin_end_tags(csr)
    unless (csr =~ Regexp.new(BEGIN_TAG))
      csr.gsub!(/-+BEGIN (NEW )?CERTIFICATE REQUEST-+/,"")
      csr = BEGIN_TAG + "\n" + csr.strip
    end
    unless (csr =~ Regexp.new(END_TAG))
      csr.gsub!(/-+END (NEW )?CERTIFICATE REQUEST-+/,"")
      csr = csr + "\n" unless csr=~/\n\Z\z/
      csr = csr + END_TAG + "\n"
    end
    csr
  end

  def to_api
    CGI::escape(body)
  end

  def is_ip_address?
    CertificateContent.is_ip_address?(common_name)
  end

  def is_server_name?
    CertificateContent.is_server_name?(common_name)
  end

  def is_fqdn?
    CertificateContent(common_name)
  end

  def is_intranet?
    CertificateContent.is_intranet?(common_name)
  end

  def is_tld?
    CertificateContent.is_tld?(common_name)
  end

  def top_level_domain
    CertificateContent.top_level_domain(common_name)
  end

  def last_dcv
    (domain_control_validations.last.try(:dcv_method)=~/https?/) ?
        domain_control_validations.last : domain_control_validations.last_sent
  end

  def non_wildcard_name
    CertificateContent.non_wildcard_name(common_name)
  end

  # secure is for https, domain is to override the csr subject
  def dcv_url(secure=false, domain=nil)
    "http#{'s' if secure}://#{domain || non_wildcard_name}/.well-known/pki-validation/#{md5_hash}.txt"
  end

  def cname_destination
    "#{dns_sha2_hash}.#{ca_tag}"
  end

  def ca_tag
    if certificate_content.blank? # for prevalidating domain with csr
      "ssl.com"
    else
      caa_issuers = certificate_content.ca.try(:caa_issuers)
      (caa_issuers[0] unless caa_issuers.blank?) || 'comodoca.com'
    end
  end

  def dcv_contents
    "#{sha2_hash}\n#{ca_tag}#{"\n#{self.unique_value}" unless self.unique_value.blank?}"
  end

  def all_names(options={})
    (subject_alternative_names and options[:san]) ? (subject_alternative_names.split(",") + [common_name]).flatten.uniq :
        [common_name]
  end

  def whois_lookup
    if whois_lookups.empty?
      whois_lookups.create
    else
      whois_lookups.last
    end
  end

  def update_whois_lookup
      whois_lookups.create
  end

  def signed_certificate_by_text=(text)
    return if text.blank?
    sc = SignedCertificate.create(body: text, csr_id: self.id)
    unless sc.errors.empty?
      logger.error "error #{self.model_and_id} signed_certificate_by_text="
      logger.error sc.errors.to_a.join(": ").to_s
      logger.error text
    end
    sc
  end

  def openssl_request
    begin
      OpenSSL::X509::Request.new(body)
    rescue Exception=>e
      logger.error e.backtrace.inspect
    end
  end

  def public_key
    openssl_request.public_key if openssl_request.is_a?(OpenSSL::X509::Request)
  end

  def verify_signature
    openssl_request.verify public_key if openssl_request
  end

  def public_key_sha1
    if new_record?
      public_key_hash(false)
    else
      Rails.cache.fetch("#{cache_key}/public_key_sha1") do
        public_key_hash(true)
      end
    end
  end
  memoize :public_key_sha1

  def decode
    begin
      openssl_request.to_text if body and openssl_request
    rescue Exception
    end
  end

  def self.decode_all
    self.find_each {|s|
      begin
        s.update_column(:decoded, s.decode.scrub) if s.decode
      rescue Exception
      end
    }
  end

  def signed_certificate_by_text
    signed_certificate.try(:body)
  end

  def signed_certificate=(signed_certificate)
    signed_certificates << signed_certificate
  end

  def replace_csr(csr)
    update_attribute :body, csr
    certificate_content.update_attribute(:workflow_state, "contacts_provided") if
        certificate_content.pending_validation?
  end

  def sig_alg_parameter
    SslcomCaApi.sig_alg_parameter(self)
  end

  def options_for_ca_dcv
    {}.tap do |options|
        options.merge!(
          'domainName' => common_name)
    end
  end

  def country
    case read_attribute(:country)
      when /united states.+/i, /usa/i
        "US"
      when /UK/i, /great britain.+/i, /england/i, /united kingdom.+/i
        "GB"
      else
        read_attribute(:country).blank? ? "" : read_attribute(:country).upcase
    end
  end

  def sent_success(with_order_num=false)
    ca_certificate_requests.all.find{|cr|cr.success? && (with_order_num ? cr.order_number : true)}
  end

  #TODO need to convert to dem - see http://support.citrix.com/article/CTX106631
  def md5_hash
    Digest::MD5.hexdigest(to_der).upcase unless body.blank?
  end

  def sha1_hash
    Digest::SHA1.hexdigest(to_der).upcase unless body.blank?
  end

  def sha2_hash
    Digest::SHA2.hexdigest(to_der).upcase unless body.blank?
  end

  def dns_md5_hash
    "_#{md5_hash}"
  end

  def dns_sha2_hash
    "#{sha2_hash[0..31]}.#{sha2_hash[32..63]}#{".#{self.unique_value}" unless self.unique_value.blank?}"
  end
  memoize :dns_sha2_hash

  def to_der
    to_openssl.to_der
  rescue
    ""
  end

  def to_openssl
    OpenSSL::X509::Request.new body
  rescue
    ""
  end

  def days_left
    SiteCheck.days_left(self.non_wildcard_name, true)
  end

  def generate_ref
    'csr-'+SecureRandom.hex(1)+Time.now.to_i.to_s(32)
  end

  def ref
    if read_attribute(:ref).blank?
      write_attribute(:ref, generate_ref)
      save unless new_record?
    end
    read_attribute(:ref)
  end

  def run_last_ca_request
    scr=sslcom_ca_requests.first
    req,res=scr.call_again
    api_log_entry=SslcomCaRequest.create(request_url: scr.request_url, parameters: req.body,
                              method: 'post', response: res.try(:body), ca: scr.ca)
    branded_sub_ca=nil
    Ca::SSL_ACCOUNT_MAPPING.each{|k,v|v.map{|k,v|branded_sub_ca=k; break if v==scr.ca}}
    ca = Ca.find_by_ca_name(branded_sub_ca || scr.ca)
    attrs = {body: api_log_entry.end_entity_certificate.to_s, ca_id: ca.id}
    sc=signed_certificates.create(attrs)
    sc.sslcom_ca_requests << api_log_entry
  end

  def get_ejbca_certificate(user_name)
    url=SslcomCaApi.ca_host + "/v1/certificate_chain"
    req,res=SslcomCaApi.call_ca(url,{},
                        SslcomCaApi.retrieve_cert_json(user_name: user_name))
    api_log_entry=SslcomCaRequest.create(request_url: url, parameters: req.body,
                                         method: 'post', response: res.try(:body))
    if res.message=="OK"
      attrs = {body: api_log_entry.end_entity_certificate.to_s, ejbca_username: user_name}
      sc=signed_certificates.create(attrs)
      sc.sslcom_ca_requests << api_log_entry
      sc
    end
  end

  # this should be run as a cron job
  def self.process_pending_server_certificates(submitted_on=1.day.ago)
    Csr.joins(:certificate_content).includes(:signed_certificates, certificate_content: :certificate_order).
        where{(certificate_content.workflow_state>>["pending_validation"]) &
          (created_at > submitted_on)}.uniq.map do |csr|
            cc = csr.certificate_content
            co = csr.certificate_order
            if cc.preferred_process_pending_server_certificates and co
              cc.dcv_verify_certificate_names unless co.domains_validated?
              co.apply_for_certificate if(
              cc.ca_id and
                  !csr.signed_certificate and
                  !csr.is_ip_address? and
                  co.paid? and
                  cc.certificate.is_server?)
            end
          end
  end

  private

  def public_key_hash(save_to_db=false)
    begin
      if read_attribute(:public_key_sha1).blank?
        write_attribute(:public_key_sha1, OpenSSL::Digest::SHA1.new(public_key.to_der).to_s)
        save if save_to_db
      end
      read_attribute(:public_key_sha1)
    rescue Exception => e
      logger.error e.backtrace.inspect
      nil
    end
  end
end
