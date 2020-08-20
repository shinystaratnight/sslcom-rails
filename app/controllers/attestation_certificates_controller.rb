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
    render json: AttestationCertificate.attestation_pass?(params[:attestation_cert], params[:attestation_issuer_cert])
  end
end
