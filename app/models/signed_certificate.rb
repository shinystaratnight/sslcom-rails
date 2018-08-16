require 'digest/md5'
require 'zip/zip'
require 'openssl'
#require 'zip/zipfilesystem'

class SignedCertificate < ActiveRecord::Base
  include CertificateType
#  using_access_control
  serialize :organization_unit
  serialize :subject_alternative_names
  belongs_to :parent, :foreign_key=>:parent_id,
    :class_name=> 'SignedCertificate', :dependent=>:destroy
  belongs_to :csr
  delegate :certificate_content, to: :csr
  delegate :certificate_order, to: :certificate_content
  belongs_to :certificate_lookup
  validates_presence_of :body, :if=> Proc.new{|r| !r.parent_cert}
  validates :csr_id, :presence=>true, :on=>:save
  validate :proper_certificate?, :if=>
    Proc.new{|r| !r.parent_cert && !r.body.blank?}
  has_many  :sslcom_ca_revocation_requests, as: :api_requestable
  #validate :same_as_previously_signed_certificate?, :if=> '!csr.blank?'

  attr :parsed
  attr_accessor :email_customer

  BEGIN_TAG="-----BEGIN CERTIFICATE-----"
  END_TAG="-----END CERTIFICATE-----"
  BEGIN_PKCS7_TAG="-----BEGIN PKCS7-----"
  END_PKCS7_TAG="-----END PKCS7-----"

  IIS_INSTALL_LINK = "https://www.ssl.com/how-to/modern-iis-ssl-installation-the-easy-way/"
  CPANEL_INSTALL_LINK = "https://www.ssl.com/how-to/install-certificate-whm-cpanel/"
  NGINX_INSTALL_LINK = "http://nginx.org/en/docs/http/configuring_https_servers.html"
  V8_NODEJS_INSTALL_LINK = "http://nodejs.org/api/https.html"
  JAVA_INSTALL_LINK = "https://www.ssl.com/how-to/how-to-install-a-certificate-on-java-based-web-servers/"
  OTHER_INSTALL_LINK = "https://www.ssl.com/article/intermediate-certificate-download/"
  APACHE_INSTALL_LINK = "https://info.ssl.com/how-to-install-a-certificate-on-apache-mod_ssl/"
  AMAZON_INSTALL_LINK = "http://aws.amazon.com/documentation/"

  APACHE_BUNDLE = "ca-bundle-client.crt"
  AMAZON_BUNDLE = "ca-chain-amazon.crt"

  OID_DV = "2.23.140.1.2.1"
  OID_OV = "2.23.140.1.2.2"
  OID_IV = "2.23.140.1.2.3"
  OID_EV = "2.23.140.1.1"
  OID_EVCS = "2.23.140.1.3"
  OID_CS = "2.23.140.1.4.1"
  OID_TEST = "2.23.140.2.1"

  after_initialize do
    if new_record?
      self.email_customer ||= false
    end
  end

  before_create do |s|
    s.decoded=s.decode
    s.serial=s.decoded_serial
    s.status ||= "issued"
  end

  after_create do |s|
    s.csr.certificate_content.issue! unless self.ca_id==Ca::ISSUER[:sslcom_shadow]
  end

  after_save do |s|
    unless self.ca_id==Ca::ISSUER[:sslcom_shadow]
      s.send_processed_certificate
      cc=s.csr.certificate_content
      if cc.preferred_reprocessing?
        cc.preferred_reprocessing=false
        cc.save
      end
      co=cc.certificate_order
      unless co.site_seal.fully_activated?
        co.site_seal.assign_attributes({workflow_state: "fully_activated"}, without_protection: true)
        co.site_seal.save
      end
      co.validation.approve! unless(co.validation.approved? || co.validation.approved_through_override?)
      last_sent=s.csr.domain_control_validations.last_sent
      last_sent.satisfy! if(last_sent && !last_sent.satisfied?)
      unless cc.url_callbacks.blank?
        cert = ApiCertificateRetrieve.new(query_type: "all_certificates")
        co.to_api_retrieve cert
        co_json = Rabl::Renderer.json(@result,File.join("api","v1","api_certificate_requests", "show_v1_4"),
                                      view_path: 'app/views', locals: {result:cert})
        cc.callback(co_json)
      end
    end
  end

  scope :live, -> {where{type == nil}}

  scope :most_recent_expiring, lambda{|start, finish|
    find_by_sql("select * from signed_certificates as T where expiration_date between '#{start}' AND '#{finish}' AND created_at = ( select max(created_at) from signed_certificates where common_name like T.common_name )")}

  def self.renew(start, finish)
    cl = CertificateLookup.includes{signed_certificates}.
        most_recent_expiring(start,finish).map(&:signed_certificates).flatten.compact
    # just update expiration date for rebilling, but do not save it to SignedCertificate
    mre=self.most_recent_expiring(start,finish).each do |sc|
        # replace signed_certificate with one from lookups
        remove = cl.select{|c|c.common_name == sc.common_name}.
            sort{|a,b|a.created_at.to_i <=> b.created_at.to_i}
        if remove.last
          sc = cl.delete(remove.last)
          remove.each {|r| cl.delete(r)}
        end
    end
    tmp_certs={}
    result = []
    cl.each do |sc|
      if tmp_certs[sc.common_name]
        tmp_certs[sc.common_name] << sc
      else
        tmp_certs.merge! sc.common_name => [sc]
      end
    end
    tmp_certs
    tmp_certs.each do |k,v|
      result << tmp_certs[k].max{|a,b|a.created_at.to_i <=> b.created_at.to_i}
    end
    expiring = (mre << result).flatten
    #expiring.each {|e|e.certificate_order.do_auto_renew}
  end

  def public_key
    openssl_x509.public_key
  end

  def public_key_sha1
    OpenSSL::Digest::SHA1.new(public_key.to_der).to_s
  end

  def common_name
    SimpleIDN.to_unicode read_attribute(:common_name)
  end

  def body=(certificate)
    return if certificate.blank?
    self[:body] = SignedCertificate.enclose_with_tags(certificate.strip)
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
            break if i>=2
            self["address#{i+1}".to_sym] = field_array("street", parsed.subject.to_s)[0]
          end
        end
        self[:signature] = parsed.subject_key_identifier
        self[:fingerprint] = OpenSSL::Digest::SHA1.new(parsed.to_der).to_s
        self[:fingerprintSHA] = "SHA1"
        self[:effective_date] = parsed.not_before
        self[:expiration_date] = parsed.not_after
        self[:subject_alternative_names] = parsed.subject_alternative_names
        #TODO ecdsa throws exception. Find better method
        self[:strength] = parsed.public_key.instance_of?(OpenSSL::PKey::EC) ?
                              parsed.to_text.match(/Public-Key\: \((\d+)/)[1] : parsed.strength
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
          certs[i][:fingerprintSHA] = @parsed[i][:fingerprint_sha]
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

  # find the ratio remaining on the cert ie (today-effective_date/expiration_date-effective_date)
  def duration_remaining
    remaining_days/total_days
  end

  def used_days(round=false)
    sum = (Time.now - effective_date)
    (round ? sum.round : sum)/1.day
  end

  def remaining_days(round=false)
    days = total_days-used_days
    (round ? days.round : days)
  end

  def total_days(round=false)
    sum = (expiration_date - effective_date)
    (round ? sum.round : sum)/1.day
  end

  def expired?
    return false unless expiration_date
    expiration_date < (Time.new)
  end

  def issuer
    openssl_x509.issuer.to_s
  end

  def is_sslcom_ca?
    issuer.include?("O=SSL Corporation") || issuer.include?("O=EJBCA Sample")
  end

  def create_signed_cert_zip_bundle(options={})
    options[:is_windows]=false unless Settings.allow_windows_cr #having issues with \r\n so stick with linux format
    co=csr.certificate_content.certificate_order
    path="/tmp/"+friendly_common_name+".zip#{Time.now.to_i.to_s(32)}"
    ::Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zos|
      co.bundled_cert_names(components: true).each do |file_name|
        file=File.new(co.bundled_cert_dir+file_name.strip, "r")
        zos.get_output_stream(file_name.strip) {|f|f.puts (options[:is_windows] ?
            file.readlines.join("").gsub(/\n/, "\r\n") : file.readlines)}
      end
      cert = options[:is_windows] ? body.gsub(/\n/, "\r\n") : body
      zos.get_output_stream(nonidn_friendly_common_name+file_extension){|f| f.puts cert}
    end
    path
  end

  def zipped_whm_bundle(is_windows=false)
    is_windows=false unless Settings.allow_windows_cr #having issues with \r\n so stick with linux format
    co=csr.certificate_content.certificate_order
    path="/tmp/"+friendly_common_name+".zip#{Time.now.to_i.to_s(32)}"
    ::Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zos|
      file=File.new(ca_bundle(is_windows: is_windows), "r")
      zos.get_output_stream(nonidn_friendly_common_name+".ca-bundle") {|f|f.puts (is_windows ?
          file.readlines.join("").gsub(/\n/, "\r\n") : file.readlines)}
      cert = is_windows ? body.gsub(/\n/, "\r\n") : body
      zos.get_output_stream(nonidn_friendly_common_name+file_extension){|f| f.puts cert}
    end
    path
  end

  def zipped_apache_bundle(is_windows=false)
    is_windows=false unless Settings.allow_windows_cr #having issues with \r\n so stick with linux format
    path="/tmp/"+friendly_common_name+".zip#{Time.now.to_i.to_s(32)}"
    ::Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zos|
      file=File.new(ca_bundle(is_windows: is_windows, is_open_ssl: true), "r")
      zos.get_output_stream(APACHE_BUNDLE) {|f|f.puts (is_windows ?
          file.readlines.join("").gsub(/\n/, "\r\n") : file.readlines)}
      cert = is_windows ? body.gsub(/\n/, "\r\n") : body
      zos.get_output_stream(nonidn_friendly_common_name+file_extension){|f| f.puts cert}
    end
    path
  end

  def zipped_amazon_bundle(is_windows=false)
    is_windows=false unless Settings.allow_windows_cr #having issues with \r\n so stick with linux format
    co=csr.certificate_content.certificate_order
    path="/tmp/"+friendly_common_name+".zip#{Time.now.to_i.to_s(32)}"
    ::Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zos|
      file=File.new(ca_bundle(is_windows: is_windows, server: "amazon"), "r")
      zos.get_output_stream(AMAZON_BUNDLE) {|f|f.puts (is_windows ?
          file.readlines.join("").gsub(/\n/, "\r\n") : file.readlines)}
      cert = is_windows ? body.gsub(/\n/, "\r\n") : body
      zos.get_output_stream(nonidn_friendly_common_name+file_extension){|f| f.puts cert}
    end
    path
  end

  def zipped_pkcs7(is_windows=false)
    is_windows=false unless Settings.allow_windows_cr #having issues with \r\n so stick with linux format
    co=csr.certificate_content.certificate_order
    path="/tmp/"+friendly_common_name+".zip#{Time.now.to_i.to_s(32)}"
    ::Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zos|
      cert = is_windows ? body.gsub(/\n/, "\r\n") : body
      zos.get_output_stream(nonidn_friendly_common_name+".p7b"){|f| f.puts to_pkcs7}
    end
    path
  end

  def send_processed_certificate(options=nil)
    # for production certs, attached the bundle, change workflow and send site seal
    unless certificate_order.certificate.is_code_signing?
      zip_path =
          if certificate_order.is_iis?
            zipped_pkcs7
          elsif certificate_order.is_nginx?
            to_nginx_file
          elsif certificate_order.is_cpanel?
            zipped_whm_bundle
          elsif certificate_order.is_apache?
            zipped_apache_bundle
          else
            create_signed_cert_zip_bundle
          end
      co=csr.certificate_content.certificate_order
      co.site_seal.fully_activate! unless co.site_seal.fully_activated?
      if email_customer
        co.processed_recipients.map{|r|r.split(" ")}.flatten.uniq.each do |c|
          begin
            OrderNotifier.processed_certificate_order(c, co, zip_path).deliver
            OrderNotifier.site_seal_approve(c, co).deliver
          rescue Exception=>e
            logger.error e.backtrace.inspect
          end
        end
      end
    end
    # for shadow certs, only send the certificate
    begin
      if certificate_order.certificate.cas.shadow.each do |shadow_ca|
        co.apply_for_certificate(mapping: shadow_ca)
        OrderNotifier.processed_certificate_order(Settings.shadow_certificate_recipient, co, nil,
                                                  co.shadow_certificates.last).deliver
      end
    end
    rescue Exception=>e
      logger.error e.message
      e.backtrace.each { |line| logger.error line }
    end
  end

  def friendly_common_name
    common_name ? common_name.gsub('*', 'STAR').gsub('.', '_') : csr.common_name.gsub('*', 'STAR').gsub('.', '_')
  end

  def nonidn_friendly_common_name
    SimpleIDN.to_ascii(read_attribute(:common_name) || csr.common_name).gsub('*', 'STAR').gsub('.', '_')
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

  def ca_bundle(options={})
    tmp_file="#{Rails.root}/tmp/sc_int_#{id}.txt"
    File.open(tmp_file, 'wb') do |f|
      tmp=""
      certificate_order.bundled_cert_names(options).each do |file_name|
        file=File.new(certificate_order.bundled_cert_dir+file_name.strip, "r")
        tmp << file.readlines.join("")
      end
      tmp.gsub!(/\n/, "\r\n") #if options[:is_windows]
      f.write tmp
    end
    tmp_file
  end


  def to_nginx(is_windows=nil)
    "".tap do |tmp|
      tmp << body+"\n"
      certificate_order.bundled_cert_names(is_open_ssl: true, ascending_root: true).each do |file_name|
        file=File.new(certificate_order.bundled_cert_dir+file_name.strip, "r")
        tmp << file.readlines.join("")
      end
      tmp.gsub!(/\n/, "\r\n") # if is_windows
    end
  end

  def to_nginx_file(is_windows=nil)
    tmp_file="#{Rails.root}/tmp/sc_int_#{id}.txt"
    File.open(tmp_file, 'wb') do |f|
      f.write to_nginx(is_windows)
    end
    tmp_file
  end

  def pkcs7_file
    sc_int="#{Rails.root}/tmp/sc_int_#{id}.cer"
    File.open(sc_int, 'wb') do |f|
      tmp=""
      certificate_order.bundled_cert_names(server: "iis").each do |file_name|
        file=File.new(certificate_order.bundled_cert_dir+file_name.strip, "r")
        tmp << file.readlines.join("")
      end
      f.write tmp
    end
    sc_pem="#{Rails.root}/tmp/sc_pem_#{id}.cer"
    File.open(sc_pem, 'wb') do |f|
      f.write body+"\n"
    end
    sc_pkcs7="#{Rails.root}/tmp/sc_pkcs7_#{id}.cer"
    ::CertUtil.pem_to_pkcs7(sc_pem, sc_int, sc_pkcs7)
    sc_pkcs7
  end

  def to_pem
    return body unless file_type=="PKCS#7"
    sc_pkcs7="#{Rails.root}/tmp/sc_pkcs7_#{id}.cer"
    File.open(sc_pkcs7, 'wb') do |f|
      f.write body+"\n"
    end
    sc_pem="#{Rails.root}/tmp/sc_pem_#{id}.cer"
    ::CertUtil.pkcs7_to_pem(sc_pem, sc_pkcs7)
    sc_pem
  end

  def to_pkcs7
    comodo_cert = ComodoApi.collect_ssl(certificate_order, {response_type: "pkcs7"}).certificate
    if comodo_cert
      (BEGIN_PKCS7_TAG+"\n"+comodo_cert+END_PKCS7_TAG).gsub(/\n/, "\r\n") #temporary fix
    else
      return body if body.starts_with?(BEGIN_PKCS7_TAG)
      File.read(pkcs7_file) # TODO need to fix some bug. ending characters not matching comodo's certs
    end
  end

  def to_format(options={})
    ComodoApi.collect_ssl(certificate_order, options).certificate
  end

  def file_extension
    if file_type=="PKCS#7"
      '.p7b'
    elsif certificate_order.is_iis?
      '.cer'
    else
      '.crt'
    end
  end

  def file_type
    body.starts_with?(BEGIN_PKCS7_TAG) ? 'PKCS#7' : 'X.509'
  end

  def openssl_x509
    begin
      OpenSSL::X509::Certificate.new(body)
    rescue Exception
    end
  end

  def issuer_dn
    openssl_x509.issuer.to_s(OpenSSL::X509::Name::RFC2253)
  end

  def decode
    begin
      if self.file_type=='PKCS#7'
        sc_pem="#{Rails.root}/tmp/sc_pem_#{id}.cer"
        File.open(sc_pem, 'wb') do |f|
          f.write body+"\n"
        end
        CertUtil.decode_certificate sc_pem, "pkcs7"
      else
        openssl_x509.to_text
      end
    rescue Exception
    end
  end

  def ca
    read_attribute(:ca_id).blank? ? ("comodo" if comodo_ca_id) : Ca.find(read_attribute(:ca_id))
  end

  def is_SHA2?
    decoded =~ /sha2/
  end

  def is_SHA1?
    decoded =~ /sha1/
  end

  def signature_algorithm
    if is_SHA2?
      "SHA2"
    else
      "SHA1"
    end
  end

  def self.decode_all
    self.find_each {|s|s.update_column :decoded, s.decode}
  end

  # get the serial through regular expression of the decoded cert
  def decoded_serial
    # m=decoded.match(/Serial Number:\n(.*?)\n/m)
    m=decoded.match(/Serial Number:(.*?)Signature/m)
    unless m.blank?
      if ca=="comodo"
        m[1].strip.remove(":")
        # "00"+m[1].strip.remove(":") # need to clear this up with Comodo
      else
        m[1].strip
      end
    end
  end

  def revoke!(reason)
    update_column(:status, "revoked") if ComodoApi.revoke_ssl(serial: self.serial, api_requestable: self,
                                                             refund_reason: reason)
  end

  private

  def proper_certificate?
    if Settings.csr_parser=="remote"
      errors[:base]<<'invalid certificate' unless @parsed.is_a?(Array)
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
  def self.enclose_with_tags(cert)
    if cert =~ /PKCS7/
      # it's PKCS7
      cert.gsub!(/-+BEGIN PKCS7-+/,"")
      cert = BEGIN_TAG + "\n" + cert.strip
      cert.gsub!(/-+END PKCS7-+/,"")
      cert = cert + "\n" unless cert=~/\n\Z\z/
      cert = cert + END_TAG + "\n"
    else
      unless cert =~ Regexp.new(BEGIN_TAG)
        cert.gsub!(/-+BEGIN.+?CERTIFICATE-+/,"")
        cert = BEGIN_TAG + "\n" + cert.strip
      end
      unless cert =~ Regexp.new(END_TAG)
        cert.gsub!(/-+END.+?CERTIFICATE-+/,"")
        cert = cert + "\n" unless cert=~/\n\Z\z/
        cert = cert + END_TAG + "\n"
      end
    end
    cert
  end

  # one time utility function to populate the fingerprint column
  def self.populate_fingerprints_serials
    self.find_each {|s|
      unless s.body.blank?
        s.update_columns(serial: s.decoded_serial,
           fingerprint: OpenSSL::Digest::SHA1.new(s.openssl_x509.to_der).to_s, fingerprintSHA: "SHA1") if s.openssl_x509
      end
    }
  end
end

