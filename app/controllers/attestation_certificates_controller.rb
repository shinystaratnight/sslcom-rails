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
      root_cert_label=false
      attestation_root_certificates.each do |root_cert|
        verified = verify_signature(root_cert.strip, attest_issuer_cert.strip)

        if verified
          root_cert_label={cn: OpenSSL::X509::Certificate.new(root_cert.strip).subject.to_s}
          break
        end
      end
    end

    return root_cert_label
  end

  def attestation_root_certificates
    ["-----BEGIN CERTIFICATE-----
MIIDFzCCAf+gAwIBAgIDBAZHMA0GCSqGSIb3DQEBCwUAMCsxKTAnBgNVBAMMIFl1
YmljbyBQSVYgUm9vdCBDQSBTZXJpYWwgMjYzNzUxMCAXDTE2MDMxNDAwMDAwMFoY
DzIwNTIwNDE3MDAwMDAwWjArMSkwJwYDVQQDDCBZdWJpY28gUElWIFJvb3QgQ0Eg
U2VyaWFsIDI2Mzc1MTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMN2
cMTNR6YCdcTFRxuPy31PabRn5m6pJ+nSE0HRWpoaM8fc8wHC+Tmb98jmNvhWNE2E
ilU85uYKfEFP9d6Q2GmytqBnxZsAa3KqZiCCx2LwQ4iYEOb1llgotVr/whEpdVOq
joU0P5e1j1y7OfwOvky/+AXIN/9Xp0VFlYRk2tQ9GcdYKDmqU+db9iKwpAzid4oH
BVLIhmD3pvkWaRA2H3DA9t7H/HNq5v3OiO1jyLZeKqZoMbPObrxqDg+9fOdShzgf
wCqgT3XVmTeiwvBSTctyi9mHQfYd2DwkaqxRnLbNVyK9zl+DzjSGp9IhVPiVtGet
X02dxhQnGS7K6BO0Qe8CAwEAAaNCMEAwHQYDVR0OBBYEFMpfyvLEojGc6SJf8ez0
1d8Cv4O/MA8GA1UdEwQIMAYBAf8CAQEwDgYDVR0PAQH/BAQDAgEGMA0GCSqGSIb3
DQEBCwUAA4IBAQBc7Ih8Bc1fkC+FyN1fhjWioBCMr3vjneh7MLbA6kSoyWF70N3s
XhbXvT4eRh0hvxqvMZNjPU/VlRn6gLVtoEikDLrYFXN6Hh6Wmyy1GTnspnOvMvz2
lLKuym9KYdYLDgnj3BeAvzIhVzzYSeU77/Cupofj093OuAswW0jYvXsGTyix6B3d
bW5yWvyS9zNXaqGaUmP3U9/b6DlHdDogMLu3VLpBB9bm5bjaKWWJYgWltCVgUbFq
Fqyi4+JE014cSgR57Jcu3dZiehB6UtAPgad9L5cNvua/IWRmm+ANy3O2LH++Pyl8
SREzU8onbBsjMg9QDiSf5oJLKvd/Ren+zGY7
-----END CERTIFICATE-----"]
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