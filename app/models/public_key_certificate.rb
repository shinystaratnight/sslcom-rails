class PublicKeyCertificate < SignedCertificate
  belongs_to :certificate_content

  after_initialize do
    if new_record?
      self.email_customer ||= ejbca_username.blank? ? false : true
    end
  end

  after_create do |s|
    s.certificate_content.issue! unless %w(ShadowSignedCertificate ManagedCertificate).include?(self.type)
  end

  after_save do |s|
    unless %w(ShadowSignedCertificate ManagedCertificate).include?(self.type)
      cc = s.certificate_content
      if cc.preferred_reprocessing?
        cc.preferred_reprocessing = false
        cc.save
      end

      co = cc.certificate_order
      unless co.site_seal.fully_activated?
        co.site_seal.assign_attributes({workflow_state: "fully_activated"}, without_protection: true)
        co.site_seal.save
      end

      co.validation.approve! unless(co.validation.approved? || co.validation.approved_through_override?)

      unless cc.url_callbacks.blank?
        cert = ApiCertificateRetrieve.new(query_type: "all_certificates")
        co.to_api_retrieve cert, format: "nginx"
        co_json = Rabl::Renderer.json(cert,File.join("api","v1","api_certificate_requests", "show_v1_4"),
                                      view_path: 'app/views', locals: {result:cert})
        cc.callback(co_json)
      end
    end
  end

  def nonidn_friendly_common_name
    SimpleIDN.to_ascii(read_attribute(:common_name) || certificate_content.ref).gsub('*', 'STAR').gsub('.', '_')
  end

  def zipped_amazon_bundle(is_windows = false)
    is_windows = false unless Settings.allow_windows_cr #having issues with \r\n so stick with linux format
    co = certificate_content.certificate_order
    path = "/tmp/" + friendly_common_name + ".zip#{Time.now.to_i.to_s(32)}"
    ::Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zos|
      file = File.new(ca_bundle(is_windows: is_windows, server: "amazon"), "r")
      zos.get_output_stream(AMAZON_BUNDLE) {|f|f.puts (is_windows ?
                                                           file.readlines.join("").gsub(/\n/, "\r\n") : file.readlines)}
      cert = is_windows ? body.gsub(/\n/, "\r\n") : body
      zos.get_output_stream(nonidn_friendly_common_name + file_extension){|f| f.puts cert}
    end
    path
  end

  def create_public_key_cert_zip_bundle(options={})
    options[:is_windows] = false unless Settings.allow_windows_cr #having issues with \r\n so stick with linux format
    co = certificate_content.certificate_order
    path = "/tmp/" + friendly_common_name + ".zip#{Time.now.to_i.to_s(32)}"
    ::Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zos|
      if certificate_content.ca
        x509_certificates.drop(1).each do |x509_cert|
          zos.get_output_stream((x509_cert.subject.common_name || x509_cert.serial.to_s).
              gsub(/[\s\.\*\(\)]/,"_").upcase+'.crt') {|f|
            f.puts (options[:is_windows] ? x509_cert.to_s.gsub(/\n/, "\r\n") : x509_cert.to_s)
          }
        end
      else
        co.bundled_cert_names(components: true).each do |file_name|
          file = File.new(co.bundled_cert_dir + file_name.strip, "r")
          zos.get_output_stream(file_name.strip) {|f|
            f.puts (options[:is_windows] ? file.readlines.join("").gsub(/\n/, "\r\n") : file.readlines)}
        end
      end
      cert = options[:is_windows] ? body.gsub(/\n/, "\r\n") : body
      zos.get_output_stream(nonidn_friendly_common_name + file_extension){|f| f.puts cert}
    end
    path
  end

  def friendly_common_name
    (common_name || serial).gsub('*', 'STAR').gsub('.', '_')
  end

  def ejbca_username
    read_attribute(:ejbca_username) or (certificate_content.blank? ? nil : certificate_content.sslcom_ca_requests.first.try(:username))
  end
end