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
  belongs_to :certificate_lookup
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

  IIS_INSTALL_LINK = "https://support.ssl.com/Knowledgebase/Article/View/7/8/how-to-install-an-ssl-certificate-in-iis-7"
  CPANEL_INSTALL_LINK = "http://docs.cpanel.net/twiki/bin/view/AllDocumentation/WHMDocs/InstallCert"
  NGINX_INSTALL_LINK = "http://nginx.org/en/docs/http/configuring_https_servers.html"
  OTHER_INSTALL_LINK = "http://info.ssl.com/?cNode=2T0V6X&pNodes=8P3K3M"
  APACHE_INSTALL_LINK = "http://info.ssl.com/article.aspx?id=10022"

  APACHE_BUNDLE = "ca-bundle-client.crt"


  after_initialize do
    return unless new_record?
    self.email_customer ||= false
  end

  after_create do |s|
    s.csr.certificate_content.issue!
  end

  after_save do |s|
    s.send_processed_certificate if s.email_customer
    cc=s.csr.certificate_content
    co=cc.certificate_order
    co.site_seal.fully_activate! unless co.site_seal.fully_activated?
    co.validation.approve! unless(co.validation.approved? || co.validation.approved_through_override?)
    last_sent=s.csr.domain_control_validations.last_sent
    last_sent.satisfy! if(last_sent && !last_sent.satisfied?)
    if cc.preferred_reprocessing?
      cc.preferred_reprocessing=false
      cc.save
    end
  end

  scope :most_recent_expiring, lambda{|start, finish|
    find_by_sql("select * from signed_certificates as T where expiration_date between '#{start}' AND '#{finish}' AND created_at = ( select max(created_at) from signed_certificates where common_name like T.common_name )")}

  def self.renew(start, finish)
    cl = CertificateLookup.includes{signed_certificates}.
        most_recent_expiring(start,finish).map(&:signed_certificates).flatten.compact
    # just update expiration date for rebilling, but do not save it to SignedCertificate
    mre=self.most_recent_expiring(start,finish).each do |sc|
        # replace signed_certificate with one from lookups
        remove = cl.select{|c|c.common_name == sc.common_name}.
            sort{|a,b|a.created_at <=> b.created_at}
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
      result << tmp_certs[k].max{|a,b|a.created_at <=> b.created_at}
    end
    expiring = (mre << result).flatten
    #expiring.each {|e|e.certificate_order.do_auto_renew}
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
      zos.get_output_stream(nonidn_friendly_common_name+file_extension){|f| f.puts cert}
    end
    path
  end

  def zipped_whm_bundle(is_windows=false)
    co=csr.certificate_content.certificate_order
    path="/tmp/"+friendly_common_name+".zip#{Time.now.to_i.to_s(32)}"
    ::Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zos|
      file=File.new(ca_bundle(is_windows=nil), "r")
      zos.get_output_stream(nonidn_friendly_common_name+".ca-bundle") {|f|f.puts (is_windows ?
          file.readlines.join("").gsub(/\n/, "\r\n") : file.readlines)}
      cert = is_windows ? body.gsub(/\n/, "\r\n") : body
      zos.get_output_stream(nonidn_friendly_common_name+file_extension){|f| f.puts cert}
    end
    path
  end

  def zipped_apache_bundle(is_windows=false)
    co=csr.certificate_content.certificate_order
    path="/tmp/"+friendly_common_name+".zip#{Time.now.to_i.to_s(32)}"
    ::Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zos|
      file=File.new(ca_bundle(is_windows=nil), "r")
      zos.get_output_stream(APACHE_BUNDLE) {|f|f.puts (is_windows ?
          file.readlines.join("").gsub(/\n/, "\r\n") : file.readlines)}
      cert = is_windows ? body.gsub(/\n/, "\r\n") : body
      zos.get_output_stream(nonidn_friendly_common_name+file_extension){|f| f.puts cert}
    end
    path
  end

  def zipped_pkcs7(is_windows=false)
    co=csr.certificate_content.certificate_order
    path="/tmp/"+friendly_common_name+".zip#{Time.now.to_i.to_s(32)}"
    ::Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zos|
      cert = is_windows ? body.gsub(/\n/, "\r\n") : body
      zos.get_output_stream(nonidn_friendly_common_name+".p7b"){|f| f.puts to_pkcs7}
    end
    path
  end

  def send_processed_certificate
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
    co.processed_recipients.each do |c|
      OrderNotifier.processed_certificate_order(c, co, zip_path).deliver
      OrderNotifier.site_seal_approve(c, co).deliver
    end
  end

  def friendly_common_name
    common_name ? common_name.gsub('*', 'STAR').gsub('.', '_') : csr.common_name.gsub('*', 'STAR').gsub('.', '_')
  end

  def nonidn_friendly_common_name
    SimpleIDN.to_ascii(read_attribute(:common_name) || csr.common_name).gsub('*', 'STAR').gsub('.', '_')
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

  def ca_bundle(is_windows=nil)
    tmp_file="#{Rails.root}/tmp/sc_int_#{id}.txt"
    File.open(tmp_file, 'wb') do |f|
      tmp=""
      certificate_order.bundled_cert_names.each do |file_name|
        file=File.new(Settings.intermediate_certs_path+file_name.strip, "r")
        tmp << file.readlines.join("")
      end
      tmp.gsub!(/\n/, "\r\n") if is_windows
      f.write tmp
    end
    tmp_file
  end


  def to_nginx(is_windows=nil)
    "".tap do |tmp|
      tmp << body+"\n"
      #be careful since depends on filename. It's convenient right now for AddTrust, Comodo, Sslcom
      certificate_order.bundled_cert_names.sort{|a,b|b<=>a}.each do |file_name|
        file=File.new(Settings.intermediate_certs_path+file_name.strip, "r")
        tmp << file.readlines.join("")
      end
      tmp.gsub!(/\n/, "\r\n") if is_windows
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
      certificate_order.bundled_cert_names.each do |file_name|
        file=File.new(Settings.intermediate_certs_path+file_name.strip, "r")
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

  def to_pkcs7
    return body if body.starts_with?(BEGIN_PKCS7_TAG)
    File.read(pkcs7_file)
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

