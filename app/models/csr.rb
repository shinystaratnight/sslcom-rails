require 'zip/zip'
require 'zip/zipfilesystem'
require 'openssl-extensions/all'
require 'digest'

class Csr < ActiveRecord::Base
  has_many    :whois_lookups
  has_many    :signed_certificates
  has_many    :ca_certificate_requests, as: :api_requestable, dependent: :destroy
  has_many    :ca_dcv_requests, as: :api_requestable, dependent: :destroy
  has_many    :ca_dcv_resend_requests, as: :api_requestable, dependent: :destroy
  has_many    :domain_control_validations do
    def last_sent
      where(:email_address !~ 'null').last
    end
  end
  has_one     :csr_override  #used for overriding csr fields - does not include a full csr
  belongs_to  :certificate_content
  has_many    :certificate_orders, :through=>:certificate_content
  serialize   :subject_alternative_names
  validates_presence_of :body
  validates_presence_of :common_name, :if=> "!body.blank?", :message=> "field blank. Invalid csr."

  #default_scope order(:created_at.desc) #theres about 17 records without proper bodies we should clean up later
  default_scope where(:common_name.ne=>nil).order(:created_at.desc)

  scope :search, lambda {|term|
    {:conditions => ["common_name like ?", '%'+term+'%'], :include=>{:certificate_content=>:certificate_order}}
  }

  BEGIN_TAG="-----BEGIN CERTIFICATE REQUEST-----"
  END_TAG="-----END CERTIFICATE REQUEST-----"
  BEGIN_NEW_TAG="-----BEGIN NEW CERTIFICATE REQUEST-----"
  END_NEW_TAG="-----END NEW CERTIFICATE REQUEST-----"

  def body=(csr)
    csr=enclose_with_tags(csr.strip)
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
        self[:organization] = parsed.subject.organization
        self[:organization_unit] = parsed.subject.organizational_unit
        self[:state] = parsed.subject.region
        self[:locality] = parsed.subject.locality
        self[:country] = parsed.subject.country
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

  def enclose_with_tags(csr)
    csr.gsub!(/-+BEGIN NEW CERTIFICATE REQUEST-+/,"") if csr =~ /-+BEGIN NEW CERTIFICATE REQUEST-+/
    csr.gsub!(/-+END NEW CERTIFICATE REQUEST-+/,"") if csr =~ /-+END NEW CERTIFICATE REQUEST-+/
    unless (csr =~ Regexp.new(BEGIN_TAG))
      csr.gsub!(/-+BEGIN CERTIFICATE REQUEST-+/,"")
      csr = BEGIN_TAG + "\n" + csr.strip
    end
    unless (csr =~ Regexp.new(END_TAG))
      csr.gsub!(/-+END CERTIFICATE REQUEST-+/,"")
      csr = csr + "\n" unless csr=~/\n\Z$/
      csr = csr + END_TAG + "\n"
    end
    csr
  end

  def is_ip_address?
    common_name.index(/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/)==0 if common_name
  end

  def is_server_name?
    common_name.index(/\./)==nil if common_name
  end

  def is_fqdn?
    unless is_ip_address? && is_server_name?
      common_name.index(/^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix)==0 if common_name
    end
  end

  def is_intranet?
    CertificateContent.is_intranet?(common_name)
  end

  def is_tld?
    CertificateContent.is_tld?(common_name)
  end

  def top_level_domain
    if is_fqdn?
      common_name=~(/(?:.*?\.)(.+)/)
      $1
    end
  end

  def last_dcv
    (domain_control_validations.last.try(:dcv_method)=="http") ?
        domain_control_validations.last :
        domain_control_validations.last_sent
  end

  def dcv_url
    "http://#{common_name}/#{md5_hash}.txt"
  end

  def dcv_contents
    "#{sha1_hash}\ncomodoca.com"
  end

  def dcv_verified?
    begin
      timeout(Surl::TIMEOUT_DURATION) do
        r=open(dcv_url).read
        !!(r =~ Regexp.new("^#{sha1_hash}") && r =~ Regexp.new("^comodoca.com"))
      end
    rescue Exception=>e
      return false
    end
  end

  def fetch_public_site
    begin
      timeout(Surl::TIMEOUT_DURATION) do
        r=open("https://"+common_name).read unless is_intranet?
        !!(r =~ Regexp.new("^#{sha1_hash}") && r =~ Regexp.new("^comodoca.com"))
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

  def signed_certificate_by_text
    signed_certificate.try(:body)
  end

  def signed_certificate=(signed_certificate)
    signed_certificates << signed_certificate
  end
  
  def signed_certificate
    signed_certificates.last
  end

  def options_for_ca_dcv
    {}.tap do |options|
        options.merge!(
          'domainName' => common_name)
    end
  end

  def sent_success
    ca_certificate_requests.all.find{|cr|cr.success?}
  end

  #TODO need to convert to dem - see http://support.citrix.com/article/CTX106631
  def md5_hash
    Digest::MD5.hexdigest(to_der).upcase unless body.blank?
  end

  def sha1_hash
    Digest::SHA1.hexdigest(to_der).upcase unless body.blank?
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
end
