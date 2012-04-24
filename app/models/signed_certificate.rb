require 'zip/zip'
require 'openssl'
#require 'zip/zipfilesystem'

class SignedCertificate < ActiveRecord::Base
#  using_access_control
  serialize :organization_unit
  serialize :subject_alternative_names
  belongs_to :parent, :foreign_key=>:parent_id,
    :class_name=> 'SignedCertificate', :dependent=>:destroy
  belongs_to :csr
  validates_presence_of :body, :if=> Proc.new{|r| !r.parent_cert}
  validates :csr_id, :presence=>true, :on=>:save
  validate :proper_certificate?, :if=>
    Proc.new{|r| !r.parent_cert && !r.body.blank?}
  #validate :same_as_previously_signed_certificate?, :if=> '!csr.blank?'

  attr :parsed
  attr_accessor :email_customer

  BEGIN_TAG="-----BEGIN CERTIFICATE-----"
  END_TAG="-----END CERTIFICATE-----"
  BEGIN_PKCS7_TAG="-----BEGIN PKCS7-----"
  END_PKCS7_TAG="-----END PKCS7-----"

  after_initialize do
    return unless new_record?
    self.email_customer = false
  end

  after_create do |s|
    s.csr.certificate_content.issue!
  end

  after_save do |s|
    s.send_processed_certificate if s.email_customer
    cc=s.csr.certificate_content
    co=cc.certificate_order
    co.validation.approve! unless(co.validation.approved? || co.validation.approved_through_override?)
    last_sent=s.csr.domain_control_validations.last_sent
    last_sent.satisfy! if(last_sent && !last_sent.satisfied?)
    if cc.preferred_reprocessing?
      cc.preferred_reprocessing=false
      cc.save
    end
  end

  def common_name
    SimpleIDN.to_unicode read_attribute(:common_name)
  end

  def body=(certificate)
    return if certificate.blank?
    self[:body] = enclose_with_tags(certificate.strip)
    unless Settings.csr_parser=="remote"
      begin
        parsed =  if certificate=~ /PKCS7/
                    pkcs7=OpenSSL::PKCS7.new(self[:body])
                    self[:body]=pkcs7.to_s
                    pkcs7.certificates.first
                  else
                    OpenSSL::X509::Certificate.new(self[:body])
                  end
      rescue Exception => ex
        logger.error ex
        errors.add :base, 'error: could not parse certificate'
      else
        self[:parent_cert] = false
        self[:common_name] = parsed.subject.common_name
        self[:organization] = parsed.subject.organization
        self[:organization_unit] = ou_array(parsed.subject.to_s)
        self[:state] = parsed.subject.region
        self[:locality] = parsed.subject.locality
        pc=field_array("postalCode", parsed.subject.to_s)
        self[:postal_code] = pc.first unless pc.blank?
        self[:country] = parsed.subject.country
        street=field_array("street", parsed.subject.to_s)
        unless street.blank?
          street.each_with_index do |s, i|
            self["address#{i+1}".to_sym] = field_array("street", parsed.subject.to_s)[0]
            break if i>=2
          end
        end
        self[:signature] = parsed.subject_key_identifier
        self[:fingerprint] = parsed.serial
        self[:fingerprint_sha] = parsed.signature_algorithm
        self[:effective_date] = parsed.not_before
        self[:expiration_date] = parsed.not_after
        self[:subject_alternative_names] = parsed.subject_alternative_names
        self[:strength] = parsed.strength
      end
    else
      ssl_util = Savon::Client.new Settings.certificate_parser_wsdl
      begin
        response = ssl_util.parse_certificate do |soap|
          soap.body = {:csr => certificate}
        end
      rescue Exception => ex
        logger.error ex
      else
        self[:parent_cert] = false
        @parsed = response.to_hash[:multi_ref]
        unless @parsed.is_a? Array
          return
        end
        certs = []
        1.times do |i|
          certs[i] = (i == 0) ? self : certs[i-1].create_parent(:parent_cert=>true)
          certs[i][:common_name] = @parsed[i][:cn][:cn]
          certs[i][:organization] = @parsed[i][:o][:o]
          certs[i][:organization_unit] = @parsed[i][:ou][:ou]
          certs[i][:address1] = @parsed[i][:street][:street]
          certs[i][:state] = @parsed[i][:st][:st]
          certs[i][:locality] = @parsed[i][:l][:l]
          certs[i][:country] = @parsed[i][:c][:c]
          certs[i][:signature] = @parsed[i][:signature]
          certs[i][:fingerprint] = @parsed[i][:fingerprint]
          certs[i][:fingerprint_sha] = @parsed[i][:fingerprint_sha]
          certs[i][:effective_date] = @parsed[i][:eff_date]
          certs[i][:expiration_date] = @parsed[i][:exp_date]
          certs[i].save unless i==0
        end
      end
    end
  end

  def ssl_account
    csr.certificate_content.certificate_order.ssl_account
  end

  def expired?
    return false unless expiration_date
    expiration_date < (Time.new)
  end

  def create_signed_cert_zip_bundle(is_windows=false)
    co=csr.certificate_content.certificate_order
    path="/tmp/"+friendly_common_name+".zip#{Time.now.to_i.to_s(32)}"
    ::Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zos|
      co.bundled_cert_names.each do |file_name|
        file=File.new(Settings.intermediate_certs_path+file_name.strip, "r")
        zos.get_output_stream(file_name.strip) {|f|f.puts (is_windows ?
            file.readlines.join("").gsub(/\n/, "\r\n") : file.readlines)}
      end
      cert = is_windows ? body.gsub(/\n/, "\r\n") : body
      zos.get_output_stream(nonidn_friendly_common_name+co.file_extension){|f| f.puts cert}
    end
    path
  end

  def send_processed_certificate
    zip_path = create_signed_cert_zip_bundle
    co=csr.certificate_content.certificate_order
    co.site_seal.fully_activate! unless co.site_seal.fully_activated?
    co.processed_recipients.each do |c|
      OrderNotifier.processed_certificate_order(c, co, zip_path).deliver
      OrderNotifier.site_seal_approve(c, co).deliver
    end
  end

  def friendly_common_name
    common_name.gsub('*', 'STAR').gsub('.', '_')
  end

  def nonidn_friendly_common_name
    SimpleIDN.to_ascii(read_attribute(:common_name)).gsub('*', 'STAR').gsub('.', '_')
  end

  def certificate_order
    csr.certificate_content.certificate_order
  end

  def expiration_date_js
    expiration_date.to_s
  end

  def created_at_js
    created_at.to_s
  end

  def ou_array(subject)
    s=subject_to_array(subject)
    s.select do |o|
      h=Hash[*o]
      true unless (h["OU"]).blank?
    end.map{|ou|ou[1]}
  end

  def field_array(field,subject)
    s=subject_to_array(subject)
    s.select do |o|
      h=Hash[*o]
      true unless (h[field]).blank?
    end.map{|f|f[1]}
  end

  def public_cert(cn=nil,port=443)
    cn=([self.common_name]+(self.subject_alternative_names||[])).find{|n|
      CertificateContent.is_tld?(n)} unless cn
    CertificateContent.find_or_create_installed(cn)
  end

  def is_intranet?
    ([self.common_name]+(self.subject_alternative_names||[])).uniq.all? {|n|CertificateContent.is_intranet?(n)}
  end

  def is_tld?
    ([self.common_name]+(self.subject_alternative_names||[])).uniq.any? {|n|CertificateContent.is_tld?(n)}
  end

  private

  def proper_certificate?
    if Settings.csr_parser=="remote"
      errors.add_to_base 'invalid certificate' unless @parsed.is_a?(Array)
    end
  end

  def same_as_previously_signed_certificate?
    if csr.signed_certificate && csr.signed_certificate.body == body
      errors.add :base, "signed certificate is the same as previously saved one"
    end
  end

  def subject_to_array(subject)
    subject.split(/\/(?=[\w\d\.]+\=)/).reject{|o|o.blank?}.map{|o|o.split(/(?<!\\)=/)}
  end

  #openssl is very finicky and requires opening and ending tags with exactly 5(-----) dashes on each side
  def enclose_with_tags(cert)
    if cert =~ /PKCS7/
      # it's PKCS7
      cert.gsub!(/-+BEGIN PKCS7-+/,"")
      cert = BEGIN_TAG + "\n" + cert.strip
      cert.gsub!(/-+END PKCS7-+/,"")
      cert = cert + "\n" unless cert=~/\n\Z$/
      cert = cert + END_TAG + "\n"
    else
      unless cert =~ Regexp.new(BEGIN_TAG)
        cert.gsub!(/-+BEGIN CERTIFICATE-+/,"")
        cert = BEGIN_TAG + "\n" + cert.strip
      end
      unless cert =~ Regexp.new(END_TAG)
        cert.gsub!(/-+END CERTIFICATE-+/,"")
        cert = cert + "\n" unless cert=~/\n\Z$/
        cert = cert + END_TAG + "\n"
      end
    end
    cert
  end  
end

