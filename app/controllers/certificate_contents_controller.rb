class CertificateContentsController < ApplicationController
  layout 'application'

  def new_contacts

  end

  def show
    redirect_to certificate_order_path(@ssl_slug, CertificateContent.find(params[:id]).certificate_order)
  end

  # PUT /contacts/1
  # PUT /contacts/1.xml
  def update
    @certificate_content = CertificateContent.find(params[:id])
    @certificate_order   = @certificate_content.certificate_order
    @contacts_attributes = params[:certificate_content][:certificate_contacts_attributes]
    
    respond_to do |format|
      if @certificate_content.update_attributes(
          params[:certificate_content].except(:certificate_contacts_attributes)
        )
        optional_contacts? ? create_contacts_optional(params) : create_contacts_required(params)
        if @certificate_content.info_provided?
          @certificate_content.provide_contacts!
          format.html { redirect_to validation_destination(slug: @ssl_slug,
                                                           certificate_order: @certificate_content.certificate_order)
          }
        else
          flash[:notice] = 'Contacts were successfully updated.'
          format.html { redirect_to certificate_order_path(@ssl_slug, @certificate_content.certificate_order) }
          format.xml  { head :ok }
        end
      else
        @saved_contacts = current_user.ssl_account.saved_contacts
        format.html { render :file => "/contacts/index", :layout=> 'application'}
        format.xml  { render :xml =>
          @certificate_content.certificate_order.errors,
          :status => :unprocessable_entity }
      end
    end
  end

  private
  
  def create_contacts_required(params)
    CertificateContent::CONTACT_ROLES.each_with_index do |role, index|
      @current_attributes = @contacts_attributes[index.to_s]
      @saved_contact      = update_saved_contact(@current_attributes) # saved contact
      @existing_contact   = @certificate_content.send("#{role}_contact")
      
      if @existing_contact.blank?
        create_certificate_contact
      else
        update_certificate_contact
      end
    end
  end
  
  def create_contacts_optional(params)
    @contacts_attributes.each do |i, values|
      @current_attributes = values
      @saved_contact      = update_saved_contact(@current_attributes) # saved contact
      unless @current_attributes[:id].blank?
        @existing_contact = CertificateContact.find_by(id: @current_attributes[:id].to_i)
      end
      if @existing_contact.blank?
        create_certificate_contact
      else
        update_certificate_contact
      end
    end
  end

  def create_certificate_contact
    attrs = @saved_contact ? @saved_contact.attributes : @current_attributes
    @certificate_content.certificate_contacts.create(
        attrs.except(*CertificateOrder::ID_AND_TIMESTAMP)
    )
  end
  
  def update_certificate_contact
    @existing_contact.assign_attributes(@saved_contact.attributes
      .keep_if {|k,_| Contact::SYNC_FIELDS.include? k.to_sym}
      .merge(parent_id: @current_attributes[:parent_id])
    )
    if @existing_contact.changed?
      @existing_contact.save
    end
  end
  
  def update_saved_contact(params)
    cc = nil
    unless !params || params[:parent_id].blank?
      cc = CertificateContact.find_by(id: params[:parent_id])
      if cc && !params[:update_parent].blank?
        cc.assign_attributes(params.permit(Contact::SYNC_FIELDS))
        cc.save if cc.changed?
      end
    end
    cc
  end

  def optional_contacts?
    Settings.dynamic_contact_count == "on"
  end
  
  def has_all_contacts?
    if require_all_contacts?
      @certificate_content.has_all_contacts?
    else
      @certificate_content.certificate_contacts.any?
    end
  end
end
