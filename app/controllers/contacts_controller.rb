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
      list = if params[:registrants]
        @ssl_account.saved_registrants.includes(:validation_histories)
      else
        @ssl_account.saved_contacts
      end
      @all_contacts = list.order(:last_name).paginate(page: params[:page])
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
    end
    redirect_to saved_contacts_contacts_path(
      @contact.contactable.to_slug, registrants: (@contact.is_a?(Registrant) ? true : nil)
      ), notice: "Status has been successfully updated for #{@contact.company_name}."
  end

  def update
    new_params = set_registrant_type params
    respond_to do |format|
      type = new_params[:type] == 'CertificateContact' ? CertificateContact : Registrant
      if @contact.becomes(type).update_attributes(new_params)
        flash[:notice] = "#{@contact.type} was successfully updated."
        format.html { 
          redirect_to saved_contacts_contacts_path(
            @ssl_slug, registrants: (@contact.is_a?(Registrant) ? true : nil)
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
   respond_to do |format|
     flash[:notice] = "Contact was successfully deleted."
     format.html { redirect_to saved_contacts_contacts_path(@ssl_slug) }
   end
  end
  
  private

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
