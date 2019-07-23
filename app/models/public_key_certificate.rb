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
      # s.send_processed_certificate
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

      # last_sent=s.csr.domain_control_validations.last_sent
      # last_sent.satisfy! if(last_sent && !last_sent.satisfied?)

      unless cc.url_callbacks.blank?
        cert = ApiCertificateRetrieve.new(query_type: "all_certificates")
        co.to_api_retrieve cert, format: "nginx"
        co_json = Rabl::Renderer.json(cert,File.join("api","v1","api_certificate_requests", "show_v1_4"),
                                      view_path: 'app/views', locals: {result:cert})
        cc.callback(co_json)
      end
    end
  end

  # def x509_certificates
  #   SslcomCaRequest.where(username: ejbca_username).first.try(:x509_certificates) ||
  #       certificate_content.x509_certificates
  # end

  def nonidn_friendly_common_name
    SimpleIDN.to_ascii(read_attribute(:common_name) || certificate_content.ref).gsub('*', 'STAR').gsub('.', '_')
  end

  # def ca_bundle(options={})
  #   tmp_file = "#{Rails.root}/tmp/sc_int_#{id}.txt"
  #   File.open(tmp_file, 'wb') do |f|
  #     tmp = ""
  #     if certificate_content.ca
  #       x509_certificates.drop(1).each do |x509_cert|
  #         tmp << x509_cert.to_s
  #       end
  #     else
  #       certificate_order.bundled_cert_names(options).each do |file_name|
  #         file = File.new(certificate_order.bundled_cert_dir + file_name.strip, "r")
  #         tmp << file.readlines.join("")
  #       end
  #     end
  #     tmp.gsub!(/\n/, "\r\n") #if options[:is_windows]
  #     f.write tmp
  #   end
  #   tmp_file
  # end

  # def to_pkcs7
  #   if certificate_content.ca
  #     (SslcomCaRequest.where(username: ejbca_username).first.try(:pkcs7) || certificate_content.pkcs7).to_s
  #   else
  #     comodo_cert = ComodoApi.collect_ssl(certificate_order, {response_type: "pkcs7"}).certificate
  #     if comodo_cert
  #       (BEGIN_PKCS7_TAG + "\n" + comodo_cert + END_PKCS7_TAG).gsub(/\n/, "\r\n") #temporary fix
  #     else
  #       return body if body.starts_with?(BEGIN_PKCS7_TAG)
  #       File.read(pkcs7_file) # TODO need to fix some bug. ending characters not matching comodo's certs
  #     end
  #   end
  # end

  # def to_nginx(is_windows = nil, options = {})
  #   "".tap do |tmp|
  #     if certificate_content.ca_id
  #       x509_certs = if options[:order] == "reverse"
  #                    x509_certificates.reverse
  #                  elsif options[:order] == "rotate"
  #                    x509_certificates.rotate
  #                  else
  #                    x509_certificates
  #                  end
  #       x509_certs.each do |x509_cert|
  #         tmp << x509_cert.to_s
  #       end
  #     else
  #       tmp << body + "\n"
  #       certificate_order.bundled_cert_names(is_open_ssl: true, ascending_root: true).each do |file_name|
  #         file = File.new(certificate_order.bundled_cert_dir + file_name.strip, "r")
  #         tmp << file.readlines.join("")
  #       end
  #     end
  #     tmp.gsub!(/\n/, "\r\n") if is_windows
  #   end
  # end

  # def zipped_whm_bundle(is_windows = false)
  #   is_windows = false unless Settings.allow_windows_cr #having issues with \r\n so stick with linux format
  #   path = "/tmp/" + friendly_common_name + ".zip#{Time.now.to_i.to_s(32)}"
  #   ::Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zos|
  #     file = File.new(ca_bundle(is_windows: is_windows), "r")
  #     zos.get_output_stream(nonidn_friendly_common_name+".ca-bundle") {|f|f.puts (is_windows ?
  #                                                                                     file.readlines.join("").gsub(/\n/, "\r\n") : file.readlines)}
  #     cert = is_windows ? body.gsub(/\n/, "\r\n") : body
  #     zos.get_output_stream(nonidn_friendly_common_name + file_extension){|f| f.puts cert}
  #   end
  #   path
  # end

  # def zipped_apache_bundle(is_windows = false)
  #   is_windows = false unless Settings.allow_windows_cr #having issues with \r\n so stick with linux format
  #   path = "/tmp/" + friendly_common_name + ".zip#{Time.now.to_i.to_s(32)}"
  #   ::Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zos|
  #     file = File.new(ca_bundle(is_windows: is_windows, is_open_ssl: true), "r")
  #     zos.get_output_stream(APACHE_BUNDLE) {|f|f.puts (is_windows ?
  #                                                          file.readlines.join("").gsub(/\n/, "\r\n") : file.readlines)}
  #     cert = is_windows ? body.gsub(/\n/, "\r\n") : body
  #     zos.get_output_stream(nonidn_friendly_common_name + file_extension){|f| f.puts cert}
  #   end
  #   path
  # end

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

  # def pkcs7_file
  #   sc_int = "#{Rails.root}/tmp/sc_int_#{id}.cer"
  #   File.open(sc_int, 'wb') do |f|
  #     tmp = ""
  #     certificate_order.bundled_cert_names(server: "iis").each do |file_name|
  #       file = File.new(certificate_order.bundled_cert_dir + file_name.strip, "r")
  #       tmp << file.readlines.join("")
  #     end
  #     f.write tmp
  #   end
  #   sc_pem = "#{Rails.root}/tmp/sc_pem_#{id}.cer"
  #   File.open(sc_pem, 'wb') do |f|
  #     f.write body + "\n"
  #   end
  #   sc_pkcs7 = "#{Rails.root}/tmp/sc_pkcs7_#{id}.cer"
  #   ::CertUtil.pem_to_pkcs7(sc_pem, sc_int, sc_pkcs7)
  #   sc_pkcs7
  # end

  def friendly_common_name
    (common_name || serial).gsub('*', 'STAR').gsub('.', '_')
  end

  # def file_extension
  #   if file_type=="PKCS#7"
  #     '.p7b'
  #   elsif certificate_order.is_iis?
  #     '.cer'
  #   else
  #     '.crt'
  #   end
  # end

  # def file_type
  #   body.starts_with?(BEGIN_PKCS7_TAG) ? 'PKCS#7' : 'X.509'
  # end

  def ejbca_username
    read_attribute(:ejbca_username) or (certificate_content.blank? ? nil : certificate_content.sslcom_ca_requests.first.try(:username))
  end

end