class ContactsController < ApplicationController
  layout 'application'
  filter_access_to :all

  def index
    @certificate_content = CertificateContent.find params[:certificate_content_id]
    @certificate_order = @certificate_content.certificate_order
    @saved_contacts = current_user.ssl_account.saved_contacts
    respond_to do |format|
      format.html 
      format.xml  { render :xml => @contacts }
    end
  end

  def saved_contacts
    if current_user
      @all_contacts = current_user.ssl_account.all_saved_contacts
        .order(:last_name).paginate(page: params[:page])
    end
    respond_to :html
  end

  def show
    if params[:saved_contact]
      @contact = Contact.find params[:id]
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
    @contact = Contact.find(params[:id])
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
  
  def update
    @contact = Contact.find params[:id]
    new_params = set_registrant_type params
    respond_to do |format|
      if @contact.update_attributes new_params
        flash[:notice] = 'Contact was successfully updated.'
        format.html { redirect_to saved_contacts_contacts_path(@ssl_slug) }
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
   @contact = Contact.find(params[:id])
   @contact.destroy
   respond_to do |format|
     flash[:notice] = "Contact was successfully deleted."
     format.html { redirect_to saved_contacts_contacts_path(@ssl_slug) }
   end
  end
  
  private
  
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
