class YubiKeyCertificatesController < ApplicationController
  def server_bundle
    @yubi_key_certificate = YubiKeyCertificate.find(params[:id])
    send_file @yubi_key_certificate.ca_bundle(is_windows: is_client_windows?), :type => 'text', :disposition => 'attachment',
              :filename => "#{@yubi_key_certificate.nonidn_friendly_common_name}.ca-bundle"
  end

  def pkcs7
    @yubi_key_certificate = YubiKeyCertificate.find(params[:id])
    send_data @yubi_key_certificate.to_pkcs7, :type => 'text', :disposition => 'attachment',
              :filename => "#{@yubi_key_certificate.nonidn_friendly_common_name}.p7b"
  end

  def nginx
    @yubi_key_certificate = YubiKeyCertificate.find(params[:id])
    send_data @yubi_key_certificate.to_nginx, :type => 'text', :disposition => 'attachment',
              :filename => "#{@yubi_key_certificate.nonidn_friendly_common_name}.chained.crt"
  end

  def whm_zip
    @yubi_key_certificate = YubiKeyCertificate.find(params[:id])
    send_file @yubi_key_certificate.zipped_whm_bundle(is_client_windows?), :type => 'text', :disposition => 'attachment',
              :filename => "#{@yubi_key_certificate.nonidn_friendly_common_name}.zip"
  end

  def apache_zip
    @yubi_key_certificate = YubiKeyCertificate.find(params[:id])
    send_file @yubi_key_certificate.zipped_apache_bundle(is_client_windows?), :type => 'text', :disposition => 'attachment',
              :filename => "#{@yubi_key_certificate.nonidn_friendly_common_name}.zip"
  end

  def amazon_zip
    @yubi_key_certificate = YubiKeyCertificate.find(params[:id])
    send_file @yubi_key_certificate.zipped_amazon_bundle(is_client_windows?), :type => 'text', :disposition => 'attachment',
              :filename => "#{@yubi_key_certificate.nonidn_friendly_common_name}.zip"
  end

  def download
    @yubi_key_certificate = YubiKeyCertificate.find(params[:id])
    t = File.new(@yubi_key_certificate.create_yubi_key_cert_zip_bundle(
        {components: true, is_windows: is_client_windows?}), "r")

    send_file t.path, :type => 'application/zip', :disposition => 'attachment',
              :filename => @yubi_key_certificate.nonidn_friendly_common_name+'.zip'

    t.close
  end
end