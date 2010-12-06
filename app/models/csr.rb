require 'zip/zip'
require 'zip/zipfilesystem'

class Csr < ActiveRecord::Base
  using_access_control
  has_many    :whois_lookups
  has_many    :signed_certificates
  belongs_to  :certificate_content
  has_many    :certificate_orders, :through=>:certificate_content
  validates_presence_of :body
  validates_presence_of :common_name, :if=> "!body.blank?", :message=> "field blank. Invalid csr."

  named_scope :search, lambda {|term|
    {:conditions => ["common_name like ?", '%'+term+'%'], :include=>{:certificate_content=>:certificate_order}}
  }

  def body=(csr)
    ssl_util = Savon::Client.new AppConfig.csr_parser_wsdl
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

  def top_level_domain
    if is_fqdn?
      common_name=~(/(?:.*?\.)(.+)/)
      $1
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
    sc = SignedCertificate.create(:body=>text)
    unless sc.errors.empty?
      self.signed_certificate.destroy unless self.signed_certificate.blank?
      self.signed_certificate = sc
    end
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
end
