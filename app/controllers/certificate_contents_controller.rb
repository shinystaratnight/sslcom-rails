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
        #this is a hack as a result of migrating to Rails 3 since functionality broke
        #only when saving fields of the same name but different value do the contacts succesfully
        #save. so here we will ensure there are 4 contacts
        unless @certificate_content.has_all_contacts?
          CertificateContent::CONTACT_ROLES.each_with_index do |role, index|
            if @certificate_content.send("#{role}_contact").blank?
              cc_new=@certificate_content.certificate_contacts.create(
                  params[:certificate_content][:certificate_contacts_attributes][index.to_s])
            end
          end
#          cc = @certificate_content.certificate_contacts.last
#          (CertificateContent::CONTACT_ROLES-cc.roles).each do |role|
#            if @certificate_content.send("#{role}_contact").blank?
#              cc_new=@certificate_content.certificate_contacts.create(cc.attributes)
#              cc_new.clear_roles
#              cc_new.add_role! role
#            end
#          end
        end
        if @certificate_content.info_provided?
          @certificate_content.provide_contacts!
          format.html { redirect_to new_certificate_order_validation_url(
              @certificate_content.certificate_order) }
        end
        flash[:notice] = 'Contacts were successfully updated.'
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
