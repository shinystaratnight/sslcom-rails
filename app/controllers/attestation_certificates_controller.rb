class AttestationCertificatesController < ApplicationController
  def server_bundle
    @attestation_certificate = AttestationCertificate.find(params[:id])
    send_file @attestation_certificate.ca_bundle(is_windows: is_client_windows?), :type => 'text', :disposition => 'attachment',
              :filename => "#{@attestation_certificate.nonidn_friendly_common_name}.ca-bundle"
  end

  def pkcs7
    @attestation_certificate = AttestationCertificate.find(params[:id])
    send_data @attestation_certificate.to_pkcs7, :type => 'text', :disposition => 'attachment',
              :filename => "#{@attestation_certificate.nonidn_friendly_common_name}.p7b"
  end

  def nginx
    @attestation_certificate = AttestationCertificate.find(params[:id])
    send_data @attestation_certificate.to_nginx, :type => 'text', :disposition => 'attachment',
              :filename => "#{@attestation_certificate.nonidn_friendly_common_name}.chained.crt"
  end

  def whm_zip
    @attestation_certificate = AttestationCertificate.find(params[:id])
    send_file @attestation_certificate.zipped_whm_bundle(is_client_windows?), :type => 'text', :disposition => 'attachment',
              :filename => "#{@attestation_certificate.nonidn_friendly_common_name}.zip"
  end

  def apache_zip
    @attestation_certificate = AttestationCertificate.find(params[:id])
    send_file @attestation_certificate.zipped_apache_bundle(is_client_windows?), :type => 'text', :disposition => 'attachment',
              :filename => "#{@attestation_certificate.nonidn_friendly_common_name}.zip"
  end

  def amazon_zip
    @attestation_certificate = AttestationCertificate.find(params[:id])
    send_file @attestation_certificate.zipped_amazon_bundle(is_client_windows?), :type => 'text', :disposition => 'attachment',
              :filename => "#{@attestation_certificate.nonidn_friendly_common_name}.zip"
  end

  def download
    @attestation_certificate = AttestationCertificate.find(params[:id])
    t = File.new(@attestation_certificate.create_attestation_cert_zip_bundle(
        {components: true, is_windows: is_client_windows?}), "r")

    send_file t.path, :type => 'application/zip', :disposition => 'attachment',
              :filename => @attestation_certificate.nonidn_friendly_common_name+'.zip'

    t.close
  end

  def check_attestation_verification
    render json: is_cert_valid?(params[:attestation_cert], params[:attestation_issuer_cert])
  end

  private

  def is_cert_valid?(attest_cert, attest_issuer_cert)
    verified = verify_signature(attest_issuer_cert.strip, attest_cert.strip)

    if verified
      attestation_root_certificates.each do |root_cert|
        verified = verify_signature(root_cert.strip, attest_issuer_cert.strip)

        break if verified
      end
    end

    return verified
  end

  def attestation_root_certificates
    tmp_cert = "-----BEGIN CERTIFICATE-----
MIIDHjCCAgagAwIBAgIEG0BT9zANBgkqhkiG9w0BAQsFADAuMSwwKgYDVQQDEyNZ
dWJpY28gVTJGIFJvb3QgQ0EgU2VyaWFsIDQ1NzIwMDYzMTAgFw0xNDA4MDEwMDAw
MDBaGA8yMDUwMDkwNDAwMDAwMFowLjEsMCoGA1UEAxMjWXViaWNvIFUyRiBSb290
IENBIFNlcmlhbCA0NTcyMDA2MzEwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
AoIBAQC/jwYuhBVlqaiYWEMsrWFisgJ+PtM91eSrpI4TK7U53mwCIawSDHy8vUmk
5N2KAj9abvT9NP5SMS1hQi3usxoYGonXQgfO6ZXyUA9a+KAkqdFnBnlyugSeCOep
8EdZFfsaRFtMjkwz5Gcz2Py4vIYvCdMHPtwaz0bVuzneueIEz6TnQjE63Rdt2zbw
nebwTG5ZybeWSwbzy+BJ34ZHcUhPAY89yJQXuE0IzMZFcEBbPNRbWECRKgjq//qT
9nmDOFVlSRCt2wiqPSzluwn+v+suQEBsUjTGMEd25tKXXTkNW21wIWbxeSyUoTXw
LvGS6xlwQSgNpk2qXYwf8iXg7VWZAgMBAAGjQjBAMB0GA1UdDgQWBBQgIvz0bNGJ
hjgpToksyKpP9xv9oDAPBgNVHRMECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBBjAN
BgkqhkiG9w0BAQsFAAOCAQEAjvjuOMDSa+JXFCLyBKsycXtBVZsJ4Ue3LbaEsPY4
MYN/hIQ5ZM5p7EjfcnMG4CtYkNsfNHc0AhBLdq45rnT87q/6O3vUEtNMafbhU6kt
hX7Y+9XFN9NpmYxr+ekVY5xOxi8h9JDIgoMP4VB1uS0aunL1IGqrNooL9mmFnL2k
LVVee6/VR6C5+KSTCMCWppMuJIZII2v9o4dkoZ8Y7QRjQlLfYzd3qGtKbw7xaF1U
sG/5xUb/Btwb2X2g4InpiB/yt/3CpQXpiWX/K4mBvUKiGn05ZsqeY1gx4g0xLBqc
U9psmyPzK+Vsgw2jeRQ5JlKDyqE0hebfC1tvFu0CCrJFcw==
-----END CERTIFICATE-----"

    attest_root_certs = []
    attest_root_certs << tmp_cert

    return attest_root_certs
  end

  def verify_signature(parent, child)
    cert_body = SignedCertificate.enclose_with_tags(child)
    begin
      child_cert = OpenSSL::X509::Certificate.new(cert_body)
    rescue Exception => ex
      logger.error ex
      return false
    end

    cert_body = SignedCertificate.enclose_with_tags(parent)
    begin
      parent_cert = OpenSSL::X509::Certificate.new(cert_body)
    rescue Exception => ex
      logger.error ex
      return false
    end

    return child_cert.verify(parent_cert.public_key)
  end
end