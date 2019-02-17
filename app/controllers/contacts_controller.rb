class ContactsController < ApplicationController
  layout 'application'

  before_filter :find_ssl_account, only: :saved_contacts
  before_filter :find_contact, only: [:admin_update, :edit, :update, :destroy]

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

  end
  
  def create
    registrant = params[:contact][:type]=='Registrant'
    new_params = set_registrant_type(params).merge(
      contactable_id: current_user.ssl_account.id,
      contactable_type: 'SslAccount'
    )
    @contact = registrant ? Registrant.new(new_params) : CertificateContact.new(new_params)
    respond_to do |format|
      if @contact.save
        flash[:notice] = 'Contact was successfully created.'
        format.html { redirect_to saved_contacts_contacts_path(@ssl_slug) }
      else
        @contact = @contact.becomes(Contact)
        format.html { render :new }
      end
    end
  end
  
  def admin_update
    if @contact && params[:status]
      @contact.update_column(:status, Contact.statuses[params[:status]])
      validate_certificate_orders
    end
    notice_ext = @co_validated && @co_validated > 0 ? "And #{@co_validated} certificate order(s) were validated." : ""
    redirect_to saved_contacts_contacts_path(
      @contact.contactable.to_slug,
      registrants: (@contact.is_a?(Registrant) ? true : nil)
    ), notice: "Status has been successfully updated for #{@contact.company_name}. #{notice_ext}"
  end

  def update
    new_params = set_registrant_type params
    respond_to do |format|
      type = new_params[:type] == 'CertificateContact' ? CertificateContact : Registrant
      if @contact.becomes(type).update_attributes(new_params)
        flash[:notice] = "#{@contact.type} was successfully updated."
        format.html { 
          redirect_to saved_contacts_contacts_path(
            (@ssl_slug || @contact.contactable.to_slug),
            registrants: (@contact.is_a?(Registrant) ? true : nil)
          )
        }
        format.json { render json: @contact, status: :ok }
      else
        format.html { render :edit }
        format.json { render json: @contact.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @contact.destroy
    redirect_to saved_contacts_contacts_path(
      @contact.contactable.to_slug, 
      registrants: (@contact.is_a?(Registrant) ? true : nil)
    ), notice: "Contact was successfully deleted."
  end
  
  private

  def get_saved_contacts
    if current_user.is_system_admins?
      Contact.where(contactable_type: 'SslAccount', type: 'CertificateContact')
    else
      @ssl_account.saved_contacts
    end
  end

  def get_saved_registrants
    contacts = if current_user.is_system_admins?
      Contact.where(contactable_type: 'SslAccount', type: 'Registrant')
    else
      @ssl_account.saved_registrants
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
