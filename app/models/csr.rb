require 'zip/zip'
require 'zip/zipfilesystem'
require 'openssl-extensions/all'
require 'digest'
require 'net/https'
require 'uri'

class Csr < ActiveRecord::Base
  include Encodable
  
  has_many    :whois_lookups, :dependent => :destroy
  has_many    :signed_certificates, -> {SignedCertificate.live}, :dependent => :destroy
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
  belongs_to  :certificate_content
  belongs_to  :certificate_lookup
  has_one    :certificate_order, :through=>:certificate_content
  has_many    :certificate_orders, :through=>:certificate_content # api_requestable.certificate_orders compatibility
  serialize   :subject_alternative_names
  validates_presence_of :body
  validates_presence_of :common_name, :if=> "!body.blank?", :message=> "field blank. Invalid csr."

  #will_paginate
  cattr_accessor :per_page
  @@per_page = 10

  scope :search, lambda {|term|
    where(csrs.common_name =~ "%#{term}%").includes{certificate_content.certificate_order}.references(:all)
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
    csr.ref = 'csr-'+SecureRandom.hex(1)+Time.now.to_i.to_s(32)
  end

  after_create do |c|
    tmp_file = "#{Rails.root}/tmp/csr_pub-#{DateTime.now.to_i}.key"
    File.open(tmp_file, 'wb') do |f|
      f.write c.public_key
    end
    modulus = timeout(TIMEOUT_DURATION) do
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
    unless certificate_content.ca.blank?
      csr_unique_value.unique_value
    else
      if ca_certificate_requests.first and !ca_certificate_requests.first.unique_value.blank?
        ca_certificate_requests.first.unique_value # comodo has returned a unique already
      else
        if read_attribute(:unique_value).blank?
          write_attribute(:unique_value, SecureRandom.hex(5)) # generate our own
          save unless new_record?
        end
        read_attribute(:unique_value)
      end
    end
  end

  def csr_unique_value
    last_unique_value = csr_unique_values.last
    if last_unique_value.nil?
      last_unique_value = csr_unique_values.create(unique_value: SecureRandom.hex(5))
    end

    #if unique_value is expired, then new unique_value should be generated
    if (Date.today-last_unique_value.created_at.to_date).to_i > 30
      last_unique_value = csr_unique_values.create(unique_value: SecureRandom.hex(5))
    end
    last_unique_value
  end

  def common_name
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
    sslcom_ca_requests.unexpired.map(&:approval_id)
  end

  def sslcom_usernames
    sslcom_ca_requests.unexpired.map(&:username)
  end

  def sslcom_outstanding_approvals
    status=SslcomCaApi.get_status(self)[1].body
    if status=="[]" or status.blank?
      0
    else
      JSON.parse(status)
    end
  end

  def self.enclose_with_tags(csr)
    csr=remove_begin_end_tags(csr)
    unless (csr =~ Regexp.new(BEGIN_TAG))
      csr.gsub!(/-+BEGIN CERTIFICATE REQUEST-+/,"")
      csr = BEGIN_TAG + "\n" + csr.strip
    end
    unless (csr =~ Regexp.new(END_TAG))
      csr.gsub!(/-+END CERTIFICATE REQUEST-+/,"")
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

  def dcv_contents
    "#{sha2_hash}\ncomodoca.com#{"\n#{self.unique_value}" unless self.unique_value.blank?}"
  end

  def all_names(options={})
    (subject_alternative_names and options[:san]) ? (subject_alternative_names.split(",") + [common_name]).flatten.uniq :
        [common_name]
  end

  def dcv_verified?
    retries=2
    begin
      timeout(Surl::TIMEOUT_DURATION) do
        r=""
        http_or_s = "http"
        if retries<2
          http_or_s = "https"
          uri = URI.parse(dcv_url(true))
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          request = Net::HTTP::Get.new(uri.request_uri)
          response = http.request(request)
          r = response.body unless response.kind_of? Net::HTTPRedirection
        else
          r = open(dcv_url).read(redirect: false)
        end
        return http_or_s if !!(r =~ Regexp.new("^#{sha2_hash}") && r =~ Regexp.new("^comodoca.com") &&
          (self.unique_value.blank? ? true : r =~ Regexp.new("^#{self.unique_value}")))
      end
    rescue Timeout::Error, OpenURI::HTTPError, RuntimeError
      retries-=1
      if retries==0
        return false
      else
        retry
      end
    rescue Exception=>e
      return false
    end
  end

  def dcv_verify(protocol)
    begin
      timeout(Surl::TIMEOUT_DURATION) do
        if protocol=="https"
          uri = URI.parse(dcv_url(true))
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          request = Net::HTTP::Get.new(uri.request_uri)
          r = http.request(request).body
        else
          r=open(dcv_url).read
        end
        return "true" if !!(r =~ Regexp.new("^#{sha2_hash}") && r =~ Regexp.new("^comodoca.com") &&
            (self.unique_value.blank? ? true : r =~ Regexp.new("^#{self.unique_value}")))
      end
    rescue Exception=>e
      return "false"
    end
  end

  def fetch_public_site
    begin
      timeout(Surl::TIMEOUT_DURATION) do
        r=open("https://"+non_wildcard_name).read unless is_intranet?
        !!(r =~ Regexp.new("^#{sha2_hash}") && r =~ Regexp.new("^comodoca.com") &&
            (self.unique_value.blank? ? true : r =~ Regexp.new("^#{self.unique_value}")))
      end
    rescue Exception=>e
      return false
    end
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
    OpenSSL::X509::Request.new(body)
  end

  def public_key
    openssl_request.public_key
  end

  def verify_signature
    openssl_request.verify public_key
  end

  def public_key_sha1
    if read_attribute(:public_key_sha1).blank?
      write_attribute(:public_key_sha1, OpenSSL::Digest::SHA1.new(public_key.to_der).to_s)
      save unless new_record?
    end
    read_attribute(:public_key_sha1)
  end

  def decode
    begin
      openssl_request.to_text if body
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

  def signed_certificate
    signed_certificates.order(:created_at).last
  end

  def replace_csr(csr)
    update_attribute :body, csr
    certificate_content.update_attribute(:workflow_state, "contacts_provided") if
        certificate_content.pending_validation?
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
end
