class SignedCertificatesController < ApplicationController
  before_action :new_signed_certificate_from_params, :on=>:create
  filter_access_to :all, :attribute_check=>true
  filter_access_to :server_bundle, :pkcs7, :whm_zip, :nginx, :apache_zip, :amazon_zip, :download, :require=>:show

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

  def revoke
    @signed_certificate = SignedCertificate.find(params[:id])
    SystemAudit.create(
        owner: current_user,
        target: @signed_certificate,
        notes: "Revoked due to reason: #{params[:revoke_reason]}",
        action: "Revoking signed certificate serial #{@signed_certificate.serial}"
    )
    @signed_certificate.revoke!(params[:revoke_reason])
    
    if @signed_certificate.revoked?
      cc = @signed_certificate.certificate_content
      list = cc.signed_certificates.pluck(:status).uniq
      if list.count == 1 && list.include?('revoked')
        cc.revoke!
        SystemAudit.create(
          owner: current_user,
          target: cc,
          notes: "Revoked due to reason: #{params[:revoke_reason]}",
          action: 'Revoked certificate content.'
        )
      end

      SystemAudit.create(
        owner: current_user,
        target: @signed_certificate,
        notes: "Revoked due to reason: #{params[:revoke_reason]}",
        action: 'Revoked signed certificate.'
      )
      flash[:notice] = "Signed Certificate was successfully revoked."  
    else
      flash[:error] = "Something went wrong, please try again!"
    end
    redirect_to certificate_order_path(@ssl_slug, @signed_certificate.certificate_order.ref)
  end

  # POST /signed_certificates/1
  # POST /signed_certificates/1.xml
  def create
    @signed_certificate.csr = Csr.find(params[:csr_id])
    respond_to do |format|
      if @signed_certificate.save
        SystemAudit.create(owner: current_user, target: @signed_certificate,
                           notes: "manually saved certificate",
                           action: "SignedCertificateController#create")
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
    send_file @signed_certificate.ca_bundle(is_windows: is_client_windows?), :type => 'text', :disposition => 'attachment',
      :filename =>"#{@signed_certificate.nonidn_friendly_common_name}.ca-bundle"
  end

  def pkcs7
    @signed_certificate = SignedCertificate.find(params[:id])
    send_data @signed_certificate.to_pkcs7, :type => 'text', :disposition => 'attachment',
              :filename =>"#{@signed_certificate.nonidn_friendly_common_name}.p7b"
  end

  def nginx
    @signed_certificate = SignedCertificate.find(params[:id])
    send_data @signed_certificate.to_nginx, :type => 'text', :disposition => 'attachment',
              :filename =>"#{@signed_certificate.nonidn_friendly_common_name}.chained.crt"
  end

  def whm_zip
    @signed_certificate = SignedCertificate.find(params[:id])
    send_file @signed_certificate.zipped_whm_bundle(is_client_windows?), :type => 'text', :disposition => 'attachment',
              :filename =>"#{@signed_certificate.nonidn_friendly_common_name}.zip"
  end

  def apache_zip
    @signed_certificate = SignedCertificate.find(params[:id])
    send_file @signed_certificate.zipped_apache_bundle(is_client_windows?), :type => 'text', :disposition => 'attachment',
              :filename =>"#{@signed_certificate.nonidn_friendly_common_name}.zip"
  end

  def amazon_zip
    @signed_certificate = SignedCertificate.find(params[:id])
    send_file @signed_certificate.zipped_amazon_bundle(is_client_windows?), :type => 'text', :disposition => 'attachment',
              :filename =>"#{@signed_certificate.nonidn_friendly_common_name}.zip"
  end

  def download
    @signed_certificate = SignedCertificate.find(params[:id])
    t=File.new(@signed_certificate.create_signed_cert_zip_bundle(
        {components: true, is_windows: is_client_windows?}), "r")
    send_file t.path, :type => 'application/zip', :disposition => 'attachment',
              :filename => @signed_certificate.nonidn_friendly_common_name+'.zip'
    t.close
  end

  protected
  def new_signed_certificate_from_params
    @signed_certificate = SignedCertificate.new(params[:signed_certificate])
    @signed_certificate.email_customer=true if params[:email_customer]
  end
end
