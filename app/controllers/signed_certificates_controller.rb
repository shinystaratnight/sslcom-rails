class SignedCertificatesController < ApplicationController
  before_filter :new_signed_certificate_from_params, :on=>:create
  filter_access_to :all, :attribute_check=>true
  filter_access_to :server_bundle, :pkcs7, :whm_zip, :require=>:show

  # DELETE /signed_certificates/1
  # DELETE /signed_certificates/1.xml
  def destroy
    csr=@signed_certificate.csr
    @signed_certificate.destroy
    respond_to do |format|
      format.html { redirect_to(signed_certificates_url) }
      format.js {
        in_line_editor = render_to_string(:inline =>
          "<%= in_place_editor_field csr, :signed_certificate_by_text, {},
          {:field_type => 'textarea', :textarea_rows => 10,
          :textarea_cols => 30} %>", :locals => { :csr => csr })
        render :update do |page|
          page.replace_html  'show_signed_certificate', in_line_editor
        end
      }
      format.xml  { head :ok }
    end
  end

  # POST /signed_certificates/1
  # POST /signed_certificates/1.xml
  def create
    @signed_certificate.csr = Csr.find(params[:csr_id])
    respond_to do |format|
      if @signed_certificate.save
        format.html {
          flash[:notice] = 'Signed certificate was successfully created.'
          redirect_to(@signed_certificate.certificate_order) }
        format.xml  { head :ok }
        format.js   { render(json: @signed_certificate, methods:
            [:expiration_date_js, :created_at_js])}
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml =>@signed_certificate.errors, :status => :unprocessable_entity }
        format.js   { render :json=>@signed_certificate.errors.to_json}
      end
    end
  end

  def server_bundle
    @signed_certificate = SignedCertificate.find(params[:id])
    send_file @signed_certificate.ca_bundle(is_client_windows?), :type => 'text', :disposition => 'attachment',
      :filename =>"#{@signed_certificate.nonidn_friendly_common_name}.ca-bundle"
  end

  def pkcs7
    @signed_certificate = SignedCertificate.find(params[:id])
    send_data @signed_certificate.to_pkcs7, :type => 'text', :disposition => 'attachment',
              :filename =>"#{@signed_certificate.nonidn_friendly_common_name}.p7b"
  end

  def whm_zip
    @signed_certificate = SignedCertificate.find(params[:id])
    send_file @signed_certificate.zipped_whm_bundle(is_client_windows?), :type => 'text', :disposition => 'attachment',
              :filename =>"#{@signed_certificate.nonidn_friendly_common_name}.zip"
  end

  protected
  def new_signed_certificate_from_params
    @signed_certificate = SignedCertificate.new(params[:signed_certificate])
    @signed_certificate.email_customer=true if params[:email_customer]
  end
end
