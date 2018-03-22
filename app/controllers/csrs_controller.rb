class CsrsController < ApplicationController
  before_filter :find_csr, only:[:http_dcv_file, :verification_check]
  filter_access_to :all, :attribute_check=>true
  filter_access_to :country_codes, :http_dcv_file, :require=>[:create] #anyone can create read creates csrs, thus read this

  # PUT /csrs/1
  # PUT /csrs/1.xml
  def update
    respond_to do |format|
      if @csr.update_attributes(params[:csr])
        @csr.certificate_content.tap do |cc|
          cc.update_attribute(:workflow_state, "contacts_provided") if cc.pending_validation?
        end
        format.html {
          flash[:notice] = 'Csr was successfully updated.'
          redirect_to(@csr.certificate_content.certificate_order) }
        format.xml  { head :ok }
        format.js   { render :json=>@csr.to_json(:include=>:signed_certificate)}
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @csr.errors, :status => :unprocessable_entity }
        format.js   { render :json=>@csr.errors.to_json}
      end
    end
  end

  def http_dcv_file
    tmp_file="#{Rails.root}/tmp/#{@csr.md5_hash}.txt"
    File.open(tmp_file, 'wb') do |f|
      f.write @csr.dcv_contents
    end
    send_file tmp_file, :type => 'text', :disposition => 'attachment',
      :filename =>@csr.md5_hash+".txt"
  end

  def verification_check
    http_or_s = false
    if cc = CertificateContent.find_by_ref(params[:ref])
      cn = cc.certificate_names.find_by_name(params[:dcv].split('__')[1])
      cn.new_name params['new_name']
      http_or_s = cn.dcv_verify(params[:protocol])
    end

    # http_or_s=ActiveRecord::Base.find_from_model_and_id(params[:dcv]).dcv_verify(params[:protocol])
    respond_to do |format|
      format.html { render inline: http_or_s.to_s }
    end
  end

  private

  def find_csr
    @csr=Csr.find(params[:id])
  end
end
