# frozen_string_literal: false

# == Schema Information
#
# Table name: signed_certificates
#
#  id                        :integer          not null, primary key
#  address1                  :string(255)
#  address2                  :string(255)
#  body                      :text(65535)
#  common_name               :string(255)
#  country                   :string(255)
#  decoded                   :text(65535)
#  effective_date            :datetime
#  ejbca_username            :string(255)
#  expiration_date           :datetime
#  ext_customer_ref          :string(255)
#  fingerprint               :string(255)
#  fingerprintSHA            :string(255)
#  locality                  :string(255)
#  organization              :string(255)
#  organization_unit         :text(65535)
#  parent_cert               :boolean
#  postal_code               :string(255)
#  revoked_at                :datetime
#  serial                    :text(65535)      not null
#  signature                 :text(65535)
#  state                     :string(255)
#  status                    :text(65535)      not null
#  strength                  :integer
#  subject_alternative_names :text(65535)
#  type                      :string(255)
#  url                       :string(255)
#  created_at                :datetime
#  updated_at                :datetime
#  ca_id                     :integer
#  certificate_content_id    :integer
#  certificate_lookup_id     :integer
#  csr_id                    :integer
#  parent_id                 :integer
#  registered_agent_id       :integer
#
# Indexes
#
#  index_signed_certificates_cn_u_b_d_ecf_eu            (common_name,url,body,decoded,ext_customer_ref,ejbca_username)
#  index_signed_certificates_on_3_cols                  (common_name,strength)
#  index_signed_certificates_on_ca_id                   (ca_id)
#  index_signed_certificates_on_certificate_content_id  (certificate_content_id)
#  index_signed_certificates_on_certificate_lookup_id   (certificate_lookup_id)
#  index_signed_certificates_on_common_name             (common_name)
#  index_signed_certificates_on_csr_id                  (csr_id)
#  index_signed_certificates_on_csr_id_and_type         (csr_id,type)
#  index_signed_certificates_on_ejbca_username          (ejbca_username)
#  index_signed_certificates_on_fingerprint             (fingerprint)
#  index_signed_certificates_on_id_and_type             (id,type)
#  index_signed_certificates_on_parent_id               (parent_id)
#  index_signed_certificates_on_registered_agent_id     (registered_agent_id)
#  index_signed_certificates_on_strength                (strength)
#  index_signed_certificates_t_cci                      (type,certificate_content_id)
#
# Foreign Keys
#
#  fk_rails_...                                   (ca_id => cas.id) ON DELETE => restrict ON UPDATE => restrict
#  fk_signed_certificates_certificate_content_id  (certificate_content_id => certificate_contents.id) ON DELETE => restrict ON UPDATE => restrict
#

require 'digest/md5'
require 'zip/zip'
require 'openssl'
#require 'zip/zipfilesystem'

class SignedCertificate < ApplicationRecord
  include CertificateType
  include Concerns::Certificate::X509Properties

  serialize :organization_unit
  serialize :subject_alternative_names
  belongs_to :parent, foreign_key: :parent_id, class_name: 'SignedCertificate', dependent: :destroy
  belongs_to :csr, touch: true
  delegate :certificate_content, to: :csr, allow_nil: true
  delegate :certificate_order, to: :certificate_content, allow_nil: true
  belongs_to :certificate_lookup
  validates_presence_of :body, if: Proc.new { |r| !r.parent_cert }
  validates :csr_id, presence: true, on: :save
  validate :proper_certificate?, if: Proc.new { |r| !r.parent_cert && !r.body.blank? }
  has_many  :sslcom_ca_revocation_requests, as: :api_requestable
  has_many  :sslcom_ca_requests, as: :api_requestable

  belongs_to :registered_agent
  has_one :revocation, class_name: 'Revocation', foreign_key: 'revoked_signed_certificate_id'
  has_one   :replacement, through: :revocation, class_name: 'SignedCertificate',
            source: 'replacement_signed_certificate', foreign_key: 'replacement_signed_certificate_id'

  attr :parsed
  attr_accessor :email_customer

  BEGIN_TAG = '-----BEGIN CERTIFICATE-----'
  END_TAG = '-----END CERTIFICATE-----'
  BEGIN_PKCS7_TAG = '-----BEGIN PKCS7-----'
  END_PKCS7_TAG = '-----END PKCS7-----'

  IIS_INSTALL_LINK = 'https://www.ssl.com/how-to/modern-iis-ssl-installation-the-easy-way/'
  CPANEL_INSTALL_LINK = 'https://www.ssl.com/how-to/install-certificate-whm-cpanel/'
  NGINX_INSTALL_LINK = 'http://nginx.org/en/docs/http/configuring_https_servers.html'
  V8_NODEJS_INSTALL_LINK = 'http://nodejs.org/api/https.html'
  JAVA_INSTALL_LINK = 'https://www.ssl.com/how-to/how-to-install-a-certificate-on-java-based-web-servers/'
  OTHER_INSTALL_LINK = 'https://www.ssl.com/article/intermediate-certificate-download/'
  APACHE_INSTALL_LINK = 'https://www.ssl.com/how-to/install-ssl-apache-mod-ssl/'
  AMAZON_INSTALL_LINK = 'http://aws.amazon.com/documentation/'

  APACHE_BUNDLE = 'ca-bundle-client.crt'
  AMAZON_BUNDLE = 'ca-chain-amazon.crt'

  OID_DV = '2.23.140.1.2.1'
  OID_OV = '2.23.140.1.2.2'
  OID_IV = '2.23.140.1.2.3'
  OID_EV = '2.23.140.1.1'
  OID_EVCS = '2.23.140.1.3'
  OID_CS = '2.23.140.1.4.1'
  OID_DOC_SIGNING = '1.3.6.1.4.1.311.10.3.12'
  OID_TEST = '2.23.140.2.1'

  after_initialize do
    if new_record?
      self.email_customer ||= ejbca_username.blank? ? false : true
    end
  end

  before_create do |s|
    s.decoded = s.decode
    s.serial = s.decoded ? s.decoded_serial : ''
    s.status ||= 'issued'
  end

  after_create :after_create
  after_save :after_save

  scope :live, -> {where{type == nil}}

  scope :most_recent_expiring, lambda{|start, finish|
    find_by_sql("select * from signed_certificates as T where expiration_date between '#{start}' AND '#{finish}' AND created_at = ( select max(created_at) from signed_certificates where common_name like T.common_name )")}

  scope :by_public_key, lambda { |pubKey|
    where{replace(replace(decoded, ' ', ''), '\r\n', '\n') =~ '%' + pubKey + '%'}
  }

  scope :search, lambda { |term|
    where("MATCH (common_name, url, body, decoded, ext_customer_ref, ejbca_username) AGAINST ('#{term}')")
  }

  scope :search_with_terms, lambda { |term|
    term ||= ''
    term = term.strip.split(/\s(?=(?:[^']|'[^']*')*$)/)
    filters = { common_name: nil, sans: nil, effective_date: nil, expiration_date: nil, status: nil }

    filters.each {|fn, fv|
      term.delete_if { |s| s =~ Regexp.new(fn.to_s + "\\:\\'?([^']*)\\'?"); filters[fn] ||= $1; $1 }
    }
    term = term.empty? ? nil : term.join(' ')

    return nil if [term, *(filters.values)].compact.empty?

    result = self.all
    unless term.blank?
      result = result.where {
                     (common_name =~ "%#{term}%") |
                     (subject_alternative_names =~ "%#{term}%") |
                     (status =~ "%#{term}%")}
    end

    %w(common_name).each do |field|
      query = filters[field.to_sym]
      result = result.where{ common_name =~ "%#{query}%" } if query
    end

    %w(sans).each do |field|
      query = filters[field.to_sym]
      result = result.where{ subject_alternative_names =~ "%#{query}%" } if query
    end

    %w(effective_date expiration_date).each do |field|
      query = filters[field.to_sym]
      if query
        query = query.split('-')
        start = Date.strptime query[0], '%m/%d/%Y'
        finish = query[1] ? Date.strptime(query[1], '%m/%d/%Y') : start + 1.day

        if field == 'effective_date'
          result = result.where{ (effective_date >> (start..finish)) }
        elsif field == 'expiration_date'
          result = result.where{ (expiration_date >> (start..finish)) }
        end
      end
    end

    %w(status).each do |field|
      query = filters[field.to_sym]
      result = result.where{ status =~ "%#{query}%" } if query
    end

    result.uniq
  }

  def self.renew(start, finish)
    cl = CertificateLookup.includes{signed_certificates}.
        most_recent_expiring(start,finish).map(&:signed_certificates).flatten.compact
    # just update expiration date for rebilling, but do not save it to SignedCertificate
    mre = self.most_recent_expiring(start,finish).each do |sc|
        # replace signed_certificate with one from lookups
        remove = cl.select{|c|c.common_name == sc.common_name}.
            sort{|a,b|a.created_at.to_i <=> b.created_at.to_i}
        if remove.last
          sc = cl.delete(remove.last)
          remove.each {|r| cl.delete(r)}
        end
    end
    tmp_certs = {}
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

  def common_name_to_unicode
    SimpleIDN.to_unicode read_attribute(:common_name)
  end

  def body=(certificate)
    return if certificate.blank?
    self[:body] = SignedCertificate.enclose_with_tags(certificate.strip)
    unless Settings.csr_parser == 'remote'
      begin
        parsed = if certificate =~ /PKCS7/
                    pkcs7 = OpenSSL::PKCS7.new(self[:body])
                    self[:body] = pkcs7.to_s
                    pkcs7.certificates.first
                  else
                    OpenSSL::X509::Certificate.new(self[:body].strip)
                  end
      rescue Exception => ex
        logger.error ex
        errors.add :base, 'error: could not parse certificate'
      else
        self[:parent_cert] = false
        self[:common_name] = parsed.subject.common_name.force_encoding('UTF-8') if parsed.subject.common_name
        self[:organization] = parsed.subject.organization.force_encoding('UTF-8') if parsed.subject.organization
        self[:organization_unit] = ou_array(parsed.subject.to_s)
        self[:state] = parsed.subject.region.force_encoding('UTF-8') if parsed.subject.region
        self[:locality] = parsed.subject.locality.force_encoding('UTF-8') if parsed.subject.locality
        pc = field_array('postalCode', parsed.subject.to_s)
        self[:postal_code] = pc.first unless pc.blank?
        self[:country] = parsed.subject.country.force_encoding('UTF-8') if parsed.subject.country
        street = field_array('street', parsed.subject.to_s)
        unless street.blank?
          street.each_with_index do |s, i|
            break if i >= 2
            self["address#{i + 1}".to_sym] = field_array('street', parsed.subject.to_s)[0]
          end
        end
        self[:signature] = parsed.subject_key_identifier.force_encoding('UTF-8') if parsed.subject_key_identifier
        self[:fingerprint] = OpenSSL::Digest::SHA1.new(parsed.to_der).to_s
        self[:fingerprintSHA] = 'SHA1'
        self[:effective_date] = parsed.not_before
        self[:expiration_date] = parsed.not_after
        self[:subject_alternative_names] = parsed.subject_alternative_names
        #TODO ecdsa throws exception. Find better method
        self[:strength] = parsed.public_key.instance_of?(OpenSSL::PKey::EC) ?
                              (matched[1] if matched = parsed.to_text.match(/Private-Key\: \((\d+)/)) : parsed.strength
      end
    else
      ssl_util = Savon::Client.new Settings.certificate_parser_wsdl
      begin
        response = ssl_util.parse_certificate do |soap|
          soap.body = {csr: certificate}
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
          certs[i] = (i == 0) ? self : certs[i - 1].create_parent(parent_cert: true)
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
          certs[i].save unless i == 0
        end
      end
    end
  end

  def ssl_account
    csr.certificate_content.certificate_order.ssl_account
  end

  # find the ratio remaining on the cert ie (today-effective_date/expiration_date-effective_date)
  def duration_remaining
    remaining_days / total_days
  end

  def used_days(round=false)
    sum = (Time.now - effective_date)
    (round ? sum.round : sum) / 1.day
  end

  def remaining_days(round=false)
    days = total_days - used_days
    (round ? days.round : days)
  end

  def total_days(round=false)
    sum = (expiration_date - effective_date)
    (round ? sum.round : sum) / 1.day
  end

  def expired?
    return false unless expiration_date
    expiration_date < (Time.new)
  end

  def issuer
    openssl_x509.issuer.to_utf8
  end

  def is_sslcom_ca?
    ca_id != nil || ejbca_username != nil || issuer.include?('O=EJBCA Sample')
  end

  def x509_certificates
    SslcomCaRequest.where(username: ejbca_username).first.try(:x509_certificates) ||
      certificate_content.x509_certificates
  end

  def create_signed_cert_zip_bundle(options={})
    options[:is_windows] = false unless Settings.allow_windows_cr #having issues with \r\n so stick with linux format
    co = csr.certificate_content.certificate_order
    path = '/tmp/' + friendly_common_name + ".zip#{Time.now.to_i.to_s(32)}"
    ::Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zos|
      if certificate_content.ca
        x509_certificates.drop(1).each do |x509_cert|
            zos.get_output_stream((x509_cert.subject.common_name || x509_cert.serial.to_s).
              gsub(/[\s\.\*\(\)]/,'_').upcase + '.crt') {|f|
            f.puts (options[:is_windows] ? x509_cert.to_s.gsub(/\n/, "\r\n") : x509_cert.to_s)
          }
        end
      else
        co.bundled_cert_names(components: true).each do |file_name|
          file = File.new(co.bundled_cert_dir + file_name.strip, 'r')
          zos.get_output_stream(file_name.strip) {|f|
            f.puts (options[:is_windows] ? file.readlines.join('').gsub(/\n/, "\r\n") : file.readlines)}
        end
      end
      cert = options[:is_windows] ? body.gsub(/\n/, "\r\n") : body
      zos.get_output_stream(nonidn_friendly_common_name + file_extension){|f| f.puts cert}
    end
    path
  end

  def zipped_whm_bundle(is_windows=false)
    is_windows = false unless Settings.allow_windows_cr #having issues with \r\n so stick with linux format
    path = '/tmp/' + friendly_common_name + ".zip#{Time.now.to_i.to_s(32)}"
    ::Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zos|
      file = File.new(ca_bundle(is_windows: is_windows), 'r')
      zos.get_output_stream(nonidn_friendly_common_name + '.ca-bundle') {|f|f.puts (is_windows ?
          file.readlines.join('').gsub(/\n/, "\r\n") : file.readlines)}
      cert = is_windows ? body.gsub(/\n/, "\r\n") : body
      zos.get_output_stream(nonidn_friendly_common_name + file_extension){|f| f.puts cert}
    end
    path
  end

  def zipped_apache_bundle(is_windows=false)
    is_windows = false unless Settings.allow_windows_cr #having issues with \r\n so stick with linux format
    path = '/tmp/' + friendly_common_name + ".zip#{Time.now.to_i.to_s(32)}"
    ::Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zos|
      file = File.new(ca_bundle(is_windows: is_windows, is_open_ssl: true), 'r')
      zos.get_output_stream(APACHE_BUNDLE) {|f|f.puts (is_windows ?
          file.readlines.join('').gsub(/\n/, "\r\n") : file.readlines)}
      cert = is_windows ? body.gsub(/\n/, "\r\n") : body
      zos.get_output_stream(nonidn_friendly_common_name + file_extension){|f| f.puts cert}
    end
    path
  end

  def zipped_amazon_bundle(is_windows=false)
    is_windows = false unless Settings.allow_windows_cr #having issues with \r\n so stick with linux format
    co = csr.certificate_content.certificate_order
    path = '/tmp/' + friendly_common_name + ".zip#{Time.now.to_i.to_s(32)}"
    ::Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zos|
      file = File.new(ca_bundle(is_windows: is_windows, server: 'amazon'), 'r')
      zos.get_output_stream(AMAZON_BUNDLE) {|f|f.puts (is_windows ?
          file.readlines.join('').gsub(/\n/, "\r\n") : file.readlines)}
      cert = is_windows ? body.gsub(/\n/, "\r\n") : body
      zos.get_output_stream(nonidn_friendly_common_name + file_extension){|f| f.puts cert}
    end
    path
  end

  def zipped_pkcs7(is_windows=false)
    is_windows = false unless Settings.allow_windows_cr #having issues with \r\n so stick with linux format
    co = csr.certificate_content.certificate_order
    path = '/tmp/' + friendly_common_name + ".zip#{Time.now.to_i.to_s(32)}"
    ::Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zos|
      cert = is_windows ? body.gsub(/\n/, "\r\n") : body
      zos.get_output_stream(nonidn_friendly_common_name + '.p7b'){|f| f.puts to_pkcs7}
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
      certificate_order.site_seal.fully_activate! unless certificate_order.site_seal.fully_activated?
      if email_customer
        certificate_order.processed_recipients.map{|r|r.split(' ')}.flatten.uniq.each do |c|
          begin
            OrderNotifier.processed_certificate_order(contact: c,
                          certificate_order: certificate_order, file_path: zip_path).deliver
            # OrderNotifier.processed_certificate_order(contact: Settings.shadow_certificate_recipient,
            #               certificate_order: certificate_order, file_path: zip_path).deliver if certificate_order.certificate_content.ca
            OrderNotifier.site_seal_approve(c, certificate_order).deliver if certificate_order.certificate.is_server?
          rescue Exception => e
            logger.error e.backtrace.inspect
          end
        end
      end
    end
    # # for shadow certs, only send the certificate
    # begin
    #   if certificate_content.ca and !certificate_content.ca.host.include?(SslcomCaApi::PRODUCTION_IP) # no shadow cert if this is production
    #     certificate_order.certificate.cas.shadow.to_a.uniq{|ca|[ca.profile_name,ca.end_entity]}.each do |shadow_ca|
    #       certificate_order.apply_for_certificate(mapping: shadow_ca)
    #       OrderNotifier.processed_certificate_order(contact: Settings.shadow_certificate_recipient,
    #                                                 certificate_order: certificate_order,
    #                                                 certificate_content: certificate_content,
    #                                                 signed_certificate: certificate_order.shadow_certificates.last).deliver
    #     end
    #   end
    # rescue Exception=>e
    #   logger.error e.message
    #   e.backtrace.each { |line| logger.error line }
    # end
  end

  def friendly_common_name
    (common_name || csr.common_name || serial).gsub('*', 'STAR').gsub('.', '_')
  end

  def nonidn_friendly_common_name
    SimpleIDN.to_ascii(read_attribute(:common_name) || csr.common_name ||
                           certificate_content.ref).gsub('*', 'STAR').gsub('.', '_')
  end

  def expiration_date_js
    expiration_date.to_s
  end

  def created_at_js
    created_at.to_s
  end

  def ou_array(subject)
    s = subject_to_array(subject)
    s.select do |o|
      h = Hash[*o]
      true unless (h['OU']).blank?
    end.map{|ou|ou[1]}
  end

  def field_array(field,subject)
    s = subject_to_array(subject)
    s.select do |o|
      h = Hash[*o]
      true unless (h[field]).blank?
    end.map{|f|f[1]}
  end

  def public_cert(cn=nil,port=443)
    cn = ([self.common_name] + (self.subject_alternative_names || [])).find{|n|
      CertificateContent.is_tld?(n)} unless cn
    CertificateContent.find_or_create_installed(cn)
  end

  def is_intranet?
    ([self.common_name] + (self.subject_alternative_names || [])).uniq.all? {|n|CertificateContent.is_intranet?(n)}
  end

  def is_tld?
    ([self.common_name] + (self.subject_alternative_names || [])).uniq.any? {|n|CertificateContent.is_tld?(n)}
  end

  def ca_bundle(options={})
    tmp_file = "#{Rails.root}/tmp/sc_int_#{id}.txt"
    File.open(tmp_file, 'wb') do |f|
      tmp = ''
      if certificate_content.ca
        x509_certificates.drop(1).each do |x509_cert|
          tmp << x509_cert.to_s
        end
      else
        certificate_order.bundled_cert_names(options).each do |file_name|
          file = File.new(certificate_order.bundled_cert_dir + file_name.strip, 'r')
          tmp << file.readlines.join('')
        end
      end
      tmp.gsub!(/\n/, "\r\n") #if options[:is_windows]
      f.write tmp
    end
    tmp_file
  end

  def revoked_by
    SignedCertificate.where{serial =~ '%'}.last.system_audits.where{action == 'revoked'}.last.owner.login
  end

  def self.print_revoked_by(serials)
    serials.each do |serial_prefix|
      sc = SignedCertificate.where{(serial =~ "#{serial_prefix}%") & (status == 'revoked')}.last
      audit = sc.system_audits.where{action == 'revoked'}.last
      p [sc.common_name,
         serial_prefix,
         audit.owner.login,
         audit.created_at.strftime('%Y-%m-%d %H:%M:%S')]
    end
  end

  def to_nginx(is_windows=nil, options={})
    ''.tap do |tmp|
      if certificate_content.ca_id
        x509_certs = if options[:order] == 'reverse'
                     x509_certificates.reverse
                   elsif options[:order] == 'rotate'
                     x509_certificates.rotate
                   else
                     x509_certificates
                   end
        x509_certs.each do |x509_cert|
          tmp << x509_cert.to_s
        end
      else
        tmp << body + "\n"
        certificate_order.bundled_cert_names(is_open_ssl: true, ascending_root: true).each do |file_name|
          file = File.new(certificate_order.bundled_cert_dir + file_name.strip, 'r')
          tmp << file.readlines.join('')
        end
      end
      tmp.gsub!(/\n/, "\r\n") if is_windows
    end
  end

  def to_nginx_file(is_windows=nil)
    tmp_file = "#{Rails.root}/tmp/sc_int_#{id}.txt"
    File.open(tmp_file, 'wb') do |f|
      f.write to_nginx(is_windows)
    end
    tmp_file
  end

  def pkcs7_file
    sc_int = "#{Rails.root}/tmp/sc_int_#{id}.cer"
    File.open(sc_int, 'wb') do |f|
      tmp = ''
      certificate_order.bundled_cert_names(server: 'iis').each do |file_name|
        file = File.new(certificate_order.bundled_cert_dir + file_name.strip, 'r')
        tmp << file.readlines.join('')
      end
      f.write tmp
    end
    sc_pem = "#{Rails.root}/tmp/sc_pem_#{id}.cer"
    File.open(sc_pem, 'wb') do |f|
      f.write body + "\n"
    end
    sc_pkcs7 = "#{Rails.root}/tmp/sc_pkcs7_#{id}.cer"
    ::CertUtil.pem_to_pkcs7(sc_pem, sc_int, sc_pkcs7)
    sc_pkcs7
  end

  def to_pem
    return body unless file_type == 'PKCS#7'
    sc_pkcs7 = "#{Rails.root}/tmp/sc_pkcs7_#{id}.cer"
    File.open(sc_pkcs7, 'wb') do |f|
      f.write body + "\n"
    end
    sc_pem = "#{Rails.root}/tmp/sc_pem_#{id}.cer"
    ::CertUtil.pkcs7_to_pem(sc_pem, sc_pkcs7)
    sc_pem
  end

  def to_pkcs7
    if certificate_content.ca
      (SslcomCaRequest.where(username: ejbca_username).first.try(:pkcs7) || certificate_content.pkcs7).to_s
    else
      comodo_cert = ComodoApi.collect_ssl(certificate_order, {response_type: 'pkcs7'}).certificate
      if comodo_cert
        (BEGIN_PKCS7_TAG + "\n" + comodo_cert + END_PKCS7_TAG).gsub(/\n/, "\r\n") #temporary fix
      else
        return body if body.starts_with?(BEGIN_PKCS7_TAG)
        File.read(pkcs7_file) # TODO need to fix some bug. ending characters not matching comodo's certs
      end
    end
  end

  def to_format(options={})
    if certificate_content.ca
      if options[:response_type] == 'individually'
        to_nginx
      elsif options[:response_type] == 'pkcs7'
        to_pkcs7
      else
        SignedCertificate.remove_begin_end_tags(to_pkcs7)
      end
    else
      ComodoApi.collect_ssl(certificate_order, options).certificate
    end
  end

  def file_extension
    if file_type == 'PKCS#7'
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

  def decode
    begin
      if self.file_type == 'PKCS#7'
        sc_pem = "#{Rails.root}/tmp/sc_pem_#{id}.cer"
        File.open(sc_pem, 'wb') do |f|
          f.write body + "\n"
        end
        CertUtil.decode_certificate sc_pem, 'pkcs7'
      else
        openssl_x509.to_text
      end
    rescue Exception
    end
  end

  def ca
    read_attribute(:ca_id).blank? ? ('comodo' if comodo_ca_id) : Ca.find(read_attribute(:ca_id))
  end

  def is_SHA2?
    decoded =~ /sha2/
  end

  def is_SHA1?
    decoded =~ /sha1/
  end

  def signature_algorithm
    matched = decoded.match(/Signature Algorithm: (.*?)\n/)
    matched[1] if matched
  end

  def self.decode_all
    self.find_each {|s|s.update_column :decoded, s.decode}
  end

  # get the serial through regular expression of the decoded cert
  def decoded_serial
    # m=decoded.match(/Serial Number:\n(.*?)\n/m)
    m = decoded.match(/Serial Number:(.*?)Signature/m)
    unless m.blank?
      if ca == 'comodo'
        m[1].strip.remove(':')
        # "00"+m[1].strip.remove(":") # need to clear this up with Comodo
      else
        m[1].strip
      end
    end
  end

  def revoked?
    status == 'revoked'
  end

  def revoke!(reason)
    unless certificate_content.ca.blank?
      response = SslcomCaApi.revoke_ssl(self,reason)
      update_column(:status, 'revoked') if response.is_a?(SslcomCaRevocationRequest) and response.response == 'OK'
    else
      update_column(:status, 'revoked') if ComodoApi.revoke_ssl(serial: self.serial, api_requestable: self, refund_reason: reason)
    end
  end

  def ejbca_username
    read_attribute(:ejbca_username) or (csr.blank? ? nil : csr.sslcom_ca_requests.first.try(:username))
  end

  def ejbca_certificate
    host = 'https://192.168.100.5:8443/v1/certificate/pkcs10'
    options = {username: 'testdv1.ssl.com1551117126063'}
    req, res = SslcomCaApi.call_ca(host, options, options.to_json)
  end

  def self.revoke_and_reissue(fingerprints)
    SignedCertificate.live.includes(:csr).where{fingerprint >> fingerprints.map(&:downcase)}.
        find_each{|sc|
      # revoke and reissue sc
    }
  end

  private

  def proper_certificate?
    if Settings.csr_parser == 'remote'
      errors[:base] << 'invalid certificate' unless @parsed.is_a?(Array)
    end
  end

  def same_as_previously_signed_certificate?
    if csr.signed_certificate && csr.signed_certificate.body == body
      errors.add :base, 'signed certificate is the same as previously saved one'
    end
  end

  def subject_to_array(subject)
    subject.split(/\/(?=[\w\d\.]+\=)/).reject{|o|o.blank?}.map{|o|o.split(/(?<!\\)=/)}
  end

  def self.remove_begin_end_tags(certificate)
    certificate.gsub!(/-+BEGIN.+?(CERTIFICATE|PKCS7)-+/,'') if certificate =~ /-+BEGIN.+?(CERTIFICATE|PKCS7)-+/
    certificate.gsub!(/-+END.+?(CERTIFICATE|PKCS7)-+/,'') if certificate =~ /-+END.+?(CERTIFICATE|PKCS7)-+/
    certificate
  end

  # openssl is very finicky and requires opening and ending tags with exactly 5(-----) dashes on each side
  def self.enclose_with_tags(cert)
    if cert =~ /PKCS7/
      # it's PKCS7
      cert.gsub!(/-+BEGIN PKCS7-+/,'')
      cert = BEGIN_TAG + "\n" + cert.strip
      cert.gsub!(/-+END PKCS7-+/,'')
      cert = cert + "\n" unless cert =~ /\n\Z\z/
      cert = cert + END_TAG + "\n"
    else
      unless cert =~ Regexp.new(BEGIN_TAG)
        cert.gsub!(/-+BEGIN.+?CERTIFICATE-+/,'')
        cert = BEGIN_TAG + "\n" + cert.strip
      end
      unless cert =~ Regexp.new(END_TAG)
        cert.gsub!(/-+END.+?CERTIFICATE-+/,'')
        cert = cert + "\n" unless cert =~ /\n\Z\z/
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
           fingerprint: OpenSSL::Digest::SHA1.new(s.openssl_x509.to_der).to_s, fingerprintSHA: 'SHA1') if s.openssl_x509
      end
    }
  end

  def after_save
    if !csr.blank? && !%w(ShadowSignedCertificate ManagedCertificate).include?(self.type)
      send_processed_certificate
      cc = csr.certificate_content
      if cc.preferred_reprocessing?
        cc.preferred_reprocessing = false
        cc.save
      end
      co = cc.certificate_order
      unless co.site_seal.fully_activated?
        co.site_seal.assign_attributes({workflow_state: 'fully_activated'}, without_protection: true)
        co.site_seal.save
      end
      co.validation.approve! unless(co.validation.approved? || co.validation.approved_through_override?)
      last_sent = csr.domain_control_validations.last_sent
      last_sent.satisfy! if(last_sent && !last_sent.satisfied?)
      unless cc.url_callbacks.blank?
        cc.callback
      end
    end
  end

  def after_create
    csr&.certificate_content&.issue! if csr.blank? && !%w(ShadowSignedCertificate ManagedCertificate).include?(self.type)
  end
end
