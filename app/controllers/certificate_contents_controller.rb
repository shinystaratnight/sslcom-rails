class CertificateContentsController < ApplicationController
  layout 'application'

  def new_contacts

  end

  # PUT /contacts/1
  # PUT /contacts/1.xml
  def update
    @certificate_content = CertificateContent.find(params[:id])
    @certificate_order = @certificate_content.certificate_order
    respond_to do |format|
      if @certificate_content.update_attributes(params[:certificate_content])
        flash[:notice] = 'Contacts were successfully updated.'
        if @certificate_content.info_provided?
          @certificate_content.provide_contacts!
          format.html { redirect_to new_certificate_order_validation_url(
              @certificate_content.certificate_order) }
        end
        format.html { redirect_to(@certificate_content.certificate_order) }
        format.xml  { head :ok }
      else
        format.html { render :file => "/contacts/index", :layout=> 'application'}
        format.xml  { render :xml => 
          @certificate_content.certificate_order.errors,
          :status => :unprocessable_entity }
      end
    end
  end

end
