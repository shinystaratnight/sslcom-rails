class CertificateContentsController < ApplicationController
  layout 'application'

  def show
    redirect_to certificate_order_path(@ssl_slug, CertificateContent.find(params[:id]).certificate_order)
  end

  # PUT /contacts/1
  # PUT /contacts/1.xml
  def update
    @certificate_content = CertificateContent.find(params[:id])
    @certificate_order   = @certificate_content.certificate_order
    unless params[:certificate_content].nil?
      @contacts_attributes = params[:certificate_content][:certificate_contacts_attributes]
    end
    
    if Contact.optional_contacts? && optional_contacts_params?(params)
      add_saved_contact(params)        if params[:add_saved_contact]
      remove_select_contact(params)    if params[:remove_selected_contact]
      create_contact(params)           if params[:create_contact]
      update_selected_contact(params)  if params[:update_selected_contact]
      update_available_contact(params) if params[:update_available_contact]
      update_role(params)              if params[:update_role]
    else
      respond_to do |format|
        proceed = if (has_all_contacts? && !params[:certificate_content])
          true
        elsif !has_all_contacts? && !params[:certificate_content]
          false
        else
          updated = @certificate_content.update_attributes(
            params[:certificate_content].except(:certificate_contacts_attributes)
          ) 
          create_contacts_required(params) if updated
          
          updated && has_all_contacts?
        end
          
        if proceed
          if @certificate_content.info_provided?
            @certificate_content.provide_contacts!
            format.html { redirect_to new_certificate_order_validation_path(
              @ssl_slug, @certificate_content.certificate_order)
            }
          else
            flash[:notice] = 'Contacts were successfully updated.'
            format.html { redirect_to certificate_order_path(@ssl_slug, @certificate_content.certificate_order) }
            format.xml  { head :ok }
          end
        else
          if !has_all_contacts? && Contact.optional_contacts?
            flash[:error] = 'Requires at least one contact for this certificate.'
          else
            error = if @certificate_content.certificate_order.errors.any?
              @certificate_content.certificate_order.errors
            else
              missing_roles = %w(administrative billing technical validation) - @certificate_content.certificate_contacts.map(&:roles).flatten.uniq 
              "Missing information for roles: #{missing_roles.join(', ')}." if missing_roles.count > 0
            end  
            flash[:error] = error
          end
          @saved_contacts = current_user.ssl_account.saved_contacts
          format.html { render :file => "/contacts/index", :layout=> 'application'}
          format.xml  { render :xml =>
            @certificate_content.certificate_order.errors,
            :status => :unprocessable_entity }
        end
      end
    end  
  end

  private
  # 
  # Optional contacts ENABLED
  # ============================================================================
  def optional_contacts_params?(params)
    result = false
    list = %w(
      add_saved_contact
      remove_selected_contact
      create_contact
      update_selected_contact
      update_available_contact
      update_role
    )
    list.each { |param| result = true if params.include?(param) }
    result
  end
  
  def update_role(params)
    contact = find_contact_from_team params[:update_role_id]
    if contact
      cur_roles = contact.roles
      contact.roles = if params[:update_role_checked]=='false'
        cur_roles - [params[:update_role]]
      else
        cur_roles + [params[:update_role]]
      end
      contact.save
    end
    render_contacts
  end
  
  def add_saved_contact(params)
    parent_id      = params[:add_saved_contact].to_i
    saved_contact  = Contact.find parent_id
    already_exists = @certificate_content.certificate_contacts.where(parent_id: parent_id).any?
    
    if saved_contact && !already_exists
      roles = (saved_contact.roles.is_a?(String) || saved_contact.roles.blank?) ? [] : saved_contact.roles
      @certificate_content.certificate_contacts.create(
        saved_contact.attributes
          .keep_if {|k,_| (Contact::SYNC_FIELDS - [:roles]).include? k.to_sym}
          .merge(parent_id: parent_id, roles: roles)
      )
    end
    render_contacts
  end
  
  def remove_select_contact(params)
    remove = @certificate_content.certificate_contacts
      .find_by(id: params[:remove_selected_contact].to_i)
    if remove && remove.parent_id
      @certificate_content.certificate_contacts
        .where(parent_id: remove.parent_id).destroy_all
    else
      remove.destroy if remove
    end
    render_contacts
  end
  
  def create_contact(params)
    contact   = params[:contact]
    parent_id = nil
    errors    = nil
    attrs     = contact.except(*CertificateOrder::ID_AND_TIMESTAMP).except(:save_for_later)
    
    if contact[:save_for_later]=='1' # create saved contact?
      saved = @certificate_content.ssl_account.saved_contacts.create(attrs)
      errors = saved.errors unless saved.valid?
      parent_id = saved.id if saved.valid?
    end
    
    if errors.nil?
      saved = @certificate_content.certificate_contacts
        .create(attrs.merge(parent_id: parent_id))
      errors = saved.errors unless saved.valid?
    end
    
    if errors.blank?
      render_contacts
    else
      render json: errors.messages, status: :unprocessable_entity
    end
  end
  
  def update_selected_contact(params)
    parent_id = nil
    errors    = nil
    attrs     = params[:contact].except(*CertificateOrder::ID_AND_TIMESTAMP)
      .except(:save_for_later).merge(roles: [params[:contact][:roles]])
    
    if params[:contact][:save_for_later]=='1' # create saved contact?
      saved = @certificate_content.ssl_account.saved_contacts
        .create(attrs.except(:roles))
      errors = saved.errors unless saved.valid?
      parent_id = saved.id if saved.valid?
    end
    
    if errors.nil?
      found = CertificateContact.find_by(id: params[:contact][:id].to_i)
      found.assign_attributes(attrs.merge(parent_id: parent_id))
      errors = found.errors unless found.valid?
      found.save if found.changed? && errors.nil?
    end
    if errors.blank?
      render_contacts
    else
      render json: errors.messages, status: :unprocessable_entity
    end
  end
  
  def update_available_contact(params)
    contact = Contact.find_by(id: params[:contact][:id].to_i)
    if contact.update_attributes(params[:contact])
      render_contacts
    else
      render json: contact.errors.messages, status: :unprocessable_entity
    end
  end
  
  def render_contacts
    partial = render_to_string(partial: '/contacts/index_optional', layout: false)
    render json: {content: partial}, status: :ok
  end

  # 
  # Optional contacts DISABLED
  # ============================================================================
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

  def create_certificate_contact
    attrs = if @saved_contact
      @saved_contact.attributes
        .keep_if {|k,_| Contact::SYNC_FIELDS_REQUIRED.include? k.to_sym}
        .merge(parent_id: @current_attributes[:parent_id])
        .merge(roles: @current_attributes[:roles])
    else
      @current_attributes
    end
    @certificate_content.certificate_contacts.create(
        attrs.except(*CertificateOrder::ID_AND_TIMESTAMP)
    )
  end
  
  def update_certificate_contact
    attrs = if @saved_contact
      @saved_contact.attributes
        .keep_if {|k,_| Contact::SYNC_FIELDS_REQUIRED.include? k.to_sym}
        .merge(parent_id: @current_attributes[:parent_id])
        .merge(roles: @current_attributes[:roles])
    else
      @current_attributes
    end
    
    @existing_contact.assign_attributes(attrs)
    if @existing_contact.changed?
      @existing_contact.save
    end
  end
  
  def update_saved_contact(params)
    cc = nil
    unless !params || params[:parent_id].blank?
      cc = CertificateContact.find_by(id: params[:parent_id])
      if cc && !params[:update_parent].blank?
        cc.assign_attributes(params.permit(Contact::SYNC_FIELDS_REQUIRED))
        cc.save if cc.changed?
      end
    end
    cc
  end
  
  def has_all_contacts?
    if Contact.optional_contacts?
      if @certificate_content.certificate_order.certificate.is_dv?
        true
      else
        @certificate_content.certificate_contacts.any?
      end
    else
      @certificate_content.has_all_contacts?
    end
  end
  
  def find_contact_from_team(target_id)
    found = @certificate_content.certificate_contacts.find_by(id: target_id.to_i)
    found = @certificate_content.ssl_account.saved_contacts.find_by(id: found.parent_id) if found && found.parent_id
    found = @certificate_content.ssl_account.saved_contacts.find_by(id: target_id.to_i) if !found && target_id
    found
  end
end
