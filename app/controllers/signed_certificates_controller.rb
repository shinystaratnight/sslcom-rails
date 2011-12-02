class SignedCertificatesController < ApplicationController
  before_filter :new_signed_certificate_from_params, :on=>:create
  filter_access_to :all, :attribute_check=>true
  filter_access_to :server_bundle, :require=>:read

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
        @signed_certificate.send_processed_certificate if params[:email_customer]
        cc=@signed_certificate.csr.certificate_content
        co=cc.certificate_order
        co.validation.approve! unless(co.validation.approved? || co.validation.approved_through_override?)
        last_sent=@signed_certificate.csr.domain_control_validations.last_sent
        last_sent.satisfy! if(last_sent && !last_sent.satisfied?)
        if cc.preferred_reprocessing?
          cc.preferred_reprocessing=false
          cc.save
        end
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
    tmp_file="#{Rails.root}/tmp/sc_int_#{@signed_certificate.id}.txt"
    File.open(tmp_file, 'wb') do |f|
      tmp=""
      if @signed_certificate.certificate_order.is_nginx?
        tmp << @signed_certificate.body+"\n"
      end
      @signed_certificate.certificate_order.bundled_cert_names.each do |file_name|
        file=File.new(Settings.intermediate_certs_path+file_name.strip, "r")
        tmp << file.readlines.join("")
      end
      tmp.gsub!(/\n/, "\r\n") if is_client_windows?
      f.write tmp
    end
    send_file tmp_file, :type => 'text', :disposition => 'attachment',
      :filename =>"ca_bundle.txt"
  end

  protected
  def new_signed_certificate_from_params
    @signed_certificate = SignedCertificate.new(params[:signed_certificate])
  end
end
