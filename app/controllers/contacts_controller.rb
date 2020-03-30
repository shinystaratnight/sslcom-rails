class ContactsController < ApplicationController
  layout 'application'

  before_action :require_user
  before_action :find_contact, only: [:admin_update, :edit, :update, :destroy]

  filter_access_to :all
  filter_access_to :edit, :update, :show, :destroy, attribute_check: true

  def index
    @certificate_content =
      (current_user.is_system_admins? ? CertificateContent :
          current_user.ssl_account.certificate_contents).find params[:certificate_content_id]
    @certificate_order = @certificate_content.certificate_order
    @saved_contacts = @certificate_order.ssl_account.saved_contacts
    respond_to do |format|
      format.html 
      format.xml  { render :xml => @contacts }
    end
  end

  def saved_contacts
    if current_user
      @registrants = params[:registrants] == 'true'
      @all_contacts = @registrants ? get_saved_registrants : get_saved_contacts
      @all_contacts = @all_contacts.index_filter(params) if params[:commit]
      @all_contacts = @all_contacts.order(:last_name)
        .paginate(page: params[:page], per_page: 25)
    end
    respond_to :html
  end

  def enterprise_pki_service_agreement
    filename = "SSLcom Enterprise PKI Service Agreement 1.0.pdf"
    send_file File.join("public", "agreements", "enterprise_pki_agreement_1.0.pdf"),
      type: "application/pdf", filename: filename, disposition: 'inline'
  end

  def show
    if params[:saved_contact]
      find_contact
    else
      @certificate_content = CertificateContent.find params[:certificate_content_id]
      @certificate_order = @certificate_content.certificate_order
    end
    respond_to do |format|
      format.html
      format.xml  { render :xml => @contact }
    end
  end

  def new
    if params[:saved_contact]
      @contact = Contact.new  
      respond_to :html
    else  
      @certificate_content = CertificateContent.find params[:certificate_content_id]
      @certificate_order = @certificate_content.certificate_order
      respond_to do |format|
        format.html
        format.xml  { render :xml => @contact }
      end
    end
  end

  def edit
    @render_epki_registrant = @contact.show_domains?
  end
  
  def create
    if params[:contact][:epki_registrant]
      create_epki_registrant
    else
      registrant = params[:contact][:type]=='Registrant'
      new_params = set_registrant_type(params).merge(
        contactable_id: current_user.ssl_account.id,
        contactable_type: 'SslAccount'
      )
      @contact = registrant ? Registrant.new(new_params) : CertificateContact.new(new_params)
      if @contact.save
        flash[:notice] = "Contact was successfully created."
        redirect_to_index
      else
        @contact = @contact.becomes(Contact)
        render :new
      end
    end
  end

  def admin_update
    if @contact && params[:status]
      previous_status = @contact.status
      @contact.update_column(:status, Contact.statuses[params[:status]])
      SystemAudit.create(
        owner:  current_user,
        target: @contact,
        notes:  "Saved Identity #{@contact.email} status was updated from 
          '#{previous_status}' to '#{@contact.status}' by #{current_user.email}.",
        action: "Saved Identity #{@contact.email} status update."
      )
      validate_certificate_orders
    end
    notice_ext = @co_validated && @co_validated > 0 ? "And #{@co_validated} certificate order(s) were validated." : ""
    flash[:notice] = "Status has been successfully updated for #{@contact.company_name}. #{notice_ext}"
    redirect_to_index
  end

  def update
    epki_registrant = params[:contact][:epki_registrant]
    new_params = if epki_registrant
      get_epki_registrant_params
    else
      @contact.contact_iv? ? set_iv_type : set_registrant_type(params)
    end
    
    respond_to do |format|
      @render_epki_registrant = @contact.show_domains?

      type = if @contact.contact_iv?
        IndividualValidation
      else 
        new_params[:type] == 'CertificateContact' ? CertificateContact : Registrant
      end  

      if @contact.becomes(type).update_attributes(new_params)
        flash[:notice] = "#{@contact.type} was successfully updated."
        update_epki_registrant
        format.html { redirect_to_index }
        format.json { render json: @contact, status: :ok }
      else
        format.html { render :edit }
        format.json { render json: @contact.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def destroy
    if @contact.destroy
      flash[:notice] = "Contact was successfully deleted."
      redirect_to_index
    end
  end
  
  private

  def get_epki_registrant_params
    domains = params[:contact][:domains].strip.split(/[\s,]+/).map(&:strip)
    new_params = set_registrant_type(params).merge(
      contactable_id: current_user.ssl_account.id,
      contactable_type: "SslAccount",
      status: Contact::statuses[:pending_epki],
      registrant_type: Registrant::registrant_types[:organization],
      type: "Registrant",
      domains: domains
    )
    new_params.delete("epki_registrant")
    new_params
  end

  def update_epki_registrant
    if @render_epki_registrant
      flash[:notice] = "EPKI Agreement was successfully updated. Please wait for SSL.com Administrator to approve this identity."
      team_name = current_user.ssl_account.get_team_name
      SystemAudit.create(
        owner:  current_user,
        target: @contact,
        action: "Existing EPKI Agreement update request for #{team_name}",
        notes:  "User #{current_user.email} has requested changes to existing EPKI Registrant for team #{team_name}."
      )
    end
  end

  def create_epki_registrant
    new_params = get_epki_registrant_params
    @contact = Registrant.new(new_params)
    if @contact.save
      flash[:notice] = "EPKI Agreement was successfully created. Please wait for SSL.com Administrator to approve this identity."
      team_name = current_user.ssl_account.get_team_name
      SystemAudit.create(
        owner:  current_user,
        target: @contact,
        action: "New EPKI Agreement Request for #{team_name}",
        notes:  "User #{current_user.email} has requested new EPKI Registrant for team #{team_name}."
      )
      redirect_to_index
    else
      @render_epki_registrant = true
      @contact = @contact.becomes(Contact)
      render :new
    end
  end

  def redirect_to_index
    redirect_to saved_contacts_contacts_path(
      @contact.contactable.to_slug,
      registrants: (@contact.contact_ov? || @contact.contact_iv?  ? true : nil)
    )
  end

  def get_saved_contacts
    if current_user.is_system_admins? and @ssl_account.blank?
      CertificateContact.where(contactable_type: 'SslAccount')
    else
      (@ssl_account and current_user.ssl_accounts.include?(@ssl_account)) ? @ssl_account.try(:saved_contacts) :
          current_user.ssl_account.saved_contacts
    end
  end

  def get_saved_registrants
    if current_user.is_system_admins? and @ssl_account.blank?
      Contact.where(type: ['Registrant','IndividualValidation']).where(contactable_type: 'SslAccount')
    else
      Contact.where(type: ['Registrant','IndividualValidation']).where(contactable_type: 'SslAccount').
          where(contactable_id: (@ssl_account and current_user.ssl_accounts.include?(@ssl_account)) ?
                                    @ssl_account.id : current_user.ssl_account.id)
    end
  end

  def validate_certificate_orders
    # Update certificate order validation status if registrant was used in 
    # any client or s/mime certificate order
    if @contact.is_a?(Registrant) && params[:status] == 'validated'
      contacts = Contact.where(parent_id: @contact.id)
      if contacts
        @co_validated = 0
        CertificateOrder.joins(certificate_contents: :locked_registrant)
          .where("contacts.id IN (?)", contacts.ids).each do |co|
            if co.certificate.is_smime_or_client? && co.locked_registrant
              co.locked_registrant.validated!
              co.registrant.validated!
              if co.iv_ov_validated?
                cc = co.certificate_content
                unless cc.validated?
                  cc.validate!
                  @co_validated += 1
                end
              end
            end
          end
      end
    end
  end

  def find_contact
    if current_user
      @contact = if current_user.is_system_admins?
        Contact.find_by(id: params[:id])
      else
        @contact = current_user.ssl_account.all_saved_contacts.find_by(id: params[:id])
      end
    end
  end
  
  def set_iv_type
    contact = params[:contact]
    contact[:registrant_type] = nil
    contact[:type] = 'IndividualValidation'
    contact
  end

  def set_registrant_type(params)
    contact = params[:contact]
    contact[:registrant_type] = nil if (contact[:type] == 'CertificateContact')
    unless contact[:registrant_type].blank?
      contact = contact.merge(
        registrant_type: Registrant::registrant_types.key(contact[:registrant_type].to_i)
      )
    end
    contact
  end
end
