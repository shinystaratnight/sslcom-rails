class PublicKeyCertificatesController < ApplicationController
  def server_bundle
    @public_key_certificate = PublicKeyCertificate.find(params[:id])
    send_file @public_key_certificate.ca_bundle(is_windows: is_client_windows?), :type => 'text', :disposition => 'attachment',
              :filename => "#{@public_key_certificate.nonidn_friendly_common_name}.ca-bundle"
  end

  def pkcs7
    @public_key_certificate = PublicKeyCertificate.find(params[:id])
    send_data @public_key_certificate.to_pkcs7, :type => 'text', :disposition => 'attachment',
              :filename => "#{@public_key_certificate.nonidn_friendly_common_name}.p7b"
  end

  def nginx
    @public_key_certificate = PublicKeyCertificate.find(params[:id])
    send_data @public_key_certificate.to_nginx, :type => 'text', :disposition => 'attachment',
              :filename => "#{@public_key_certificate.nonidn_friendly_common_name}.chained.crt"
  end

  def whm_zip
    @public_key_certificate = PublicKeyCertificate.find(params[:id])
    send_file @public_key_certificate.zipped_whm_bundle(is_client_windows?), :type => 'text', :disposition => 'attachment',
              :filename => "#{@public_key_certificate.nonidn_friendly_common_name}.zip"
  end

  def apache_zip
    @public_key_certificate = PublicKeyCertificate.find(params[:id])
    send_file @public_key_certificate.zipped_apache_bundle(is_client_windows?), :type => 'text', :disposition => 'attachment',
              :filename => "#{@public_key_certificate.nonidn_friendly_common_name}.zip"
  end

  def amazon_zip
    @public_key_certificate = PublicKeyCertificate.find(params[:id])
    send_file @public_key_certificate.zipped_amazon_bundle(is_client_windows?), :type => 'text', :disposition => 'attachment',
              :filename => "#{@public_key_certificate.nonidn_friendly_common_name}.zip"
  end

  def download
    @public_key_certificate = PublicKeyCertificate.find(params[:id])
    t = File.new(@public_key_certificate.create_public_key_cert_zip_bundle(
        {components: true, is_windows: is_client_windows?}), "r")

    send_file t.path, :type => 'application/zip', :disposition => 'attachment',
              :filename => @public_key_certificate.nonidn_friendly_common_name+'.zip'

    t.close
  end
end