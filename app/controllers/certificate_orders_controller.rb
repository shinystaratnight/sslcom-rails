class CertificateOrdersController < ApplicationController
  layout 'application'
  include OrdersHelper
  before_filter :load_certificate_order, only: [:update, :edit]
  filter_access_to :all
  filter_access_to :credits, :incomplete, :pending, :search, :require=>:read
  filter_access_to :set_csr_signed_certificate_by_text, :update_csr, :download,
    :renew, :reprocess, :require=>[:create, :update, :delete]
  before_filter :require_user, :if=>'current_subdomain==Reseller::SUBDOMAIN'
  cache_sweeper :certificate_order_sweeper
  in_place_edit_for :certificate_order, :notes
  in_place_edit_for :csr, :signed_certificate_by_text

  def search
    index
  end

  # GET /certificate_orders
  # GET /certificate_orders.xml
  def index
#    expire_fragment('admin_header_certs_status') if
#      fragment_exist?('admin_header_certs_status')
    p = {:page => params[:page]}
    @certificate_orders = find_certificate_orders.paginate(p)

    respond_to do |format|
      format.html { render :action => :index }
      format.xml  { render :xml => @certificate_orders }
    end
  end

  # GET /certificate_orders/1
  # GET /certificate_orders/1.xml
  def show
    @certificate_order = CertificateOrder.find_by_ref(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @certificate_order }
    end
  end

  def renew
    action = CertificateOrder::RENEWING
    iv = recert(action)
    unless iv.blank?
      redirect_to buy_certificate_url(iv.renewal_certificate,
        {action.to_sym=>params[:id]})
    else
      not_found
    end
  end

  # GET /certificate_orders/new
  # GET /certificate_orders/new.xml
#  def new
#    @certificate_order = CertificateOrder.new
#    @certificate_content = @certificate_order.certificate_content
#    respond_to do |format|
#      format.html # new.html.erb
#      format.xml  { render :xml => @certificate_order }
#    end
#  end

  # GET /certificate_orders/1/edit
  def edit
    unless @certificate_order.blank?
      if @certificate_order.is_unused_credit?
        @certificate_order.has_csr=true
        @certificate = @certificate_order.mapped_certificate
        @certificate_content = @certificate_order.certificate_content
        return render '/certificates/buy', :layout=>'application'
      end
      csr = @certificate_order.certificate_content.csr
      setup_registrant()
      @registrant.company_name = csr.organization
      @registrant.department = csr.organization_unit
      @registrant.city = csr.locality
      @registrant.state = csr.state
      @registrant.email = csr.email
      @registrant.country = csr.country
    else
      not_found
    end
  end

  # GET /certificate_orders/1/reprocess
  def reprocess
    @certificate_order = recert(CertificateOrder::REPROCESSING)
    unless @certificate_order.blank?
      @certificate_order.has_csr=true
      @certificate = @certificate_order.mapped_certificate
      @certificate_content = @certificate_order.certificate_contents.build
      return render '/certificates/buy', :layout=>'application'
    else
      not_found
    end
  end

  # POST /certificate_orders
  # POST /certificate_orders.xml
  def create
    redirect_to new_order_url and return unless current_user
    certificate_order = CertificateOrder.new(params[:certificate_order])
    @certificate = Certificate.find_by_product(params[:certificate][:product])
    determine_eligibility_to_buy(@certificate, certificate_order)
    @certificate_order = setup_certificate_order(@certificate, certificate_order)
    respond_to do |format|
      if @certificate_order.save
        unless is_reseller? && !(current_order.amount.cents >
              current_user.ssl_account.funded_account.amount.cents)
          format.html {redirect_to allocate_funds_for_order_path(:id=>
                'certificate')}
        else
          format.html {redirect_to confirm_funds_path(:id=>'certificate_order')}
        end
      else
        format.html { render(:template => "/certificates/buy", :layout=>"application")}
      end
    end
  end

  # PUT /certificate_orders/1
  # PUT /certificate_orders/1.xml
  def update
    respond_to do |format|
      if @certificate_order.update_attributes(params[:certificate_order])
        cc = @certificate_order.certificate_content
        if cc.csr_submitted?
          cc.provide_info!
          if current_user.ssl_account.is_registered_reseller?
            @order = @certificate_order.order
            unless @order.deducted_from.blank?
              @deposit = @order.deducted_from
              @profile = @deposit.billing_profile
            end
            CertificateContent::CONTACT_ROLES.each do |role|
              c = CertificateContact.new
              r = current_user.ssl_account.reseller
              CertificateContent::RESELLER_FIELDS_TO_COPY.each do |field|
                c.send((field+'=').to_sym, r.send(field.to_sym))
              end
              c.company_name = r.organization
              c.country = Country.find_by_name_caps(r.country.upcase).iso1_code
              c.clear_roles
              c.add_role! role
              cc.certificate_contacts << c
              cc.update_attribute(role+"_checkbox", true) unless
                role==CertificateContent::ADMINISTRATIVE_ROLE
            end
            unless @certificate_order.certificate.is_ev?
              cc.provide_contacts!
              cc.pend_validation!
            end
          end
          if @certificate_order.
              signup_process[:label]==CertificateOrder::EXPRESS
            format.html { render :template => '/funded_accounts/success' }
          else #assume ev full signup process
            format.html { redirect_to certificate_content_contacts_url(cc) }
          end
        end
        format.html { redirect_to edit_certificate_order_url(@certificate_order) }
        format.xml  { head :ok }
      else
        @registrant=Registrant.new(
            params[:certificate_order][:certificate_contents_attributes]['0'][:registrant_attributes])
        format.html { render :action => "edit" }
        format.xml  { render :xml => @certificate_order.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /certificate_orders/1
  # PUT /certificate_orders/1.xml
  def update_csr
    @certificate_order = CertificateOrder.find_by_ref(params[:id])
    @certificate_content=CertificateContent.new(
      params[:certificate_order][:certificate_contents_attributes]['0'.to_sym])
    @certificate_content.certificate_order=@certificate_order
    @certificate_content.preferred_reprocessing=true if eval("@#{CertificateOrder::REPROCESSING}")

    respond_to do |format|
      if @certificate_content.valid?
        cc = @certificate_order.certificate_content
        if @certificate_content.preferred_reprocessing?
          @certificate_order.certificate_contents << @certificate_content
          @certificate_content.create_registrant(cc.registrant.attributes).save
          cc.certificate_contacts.each do |contact|
            @certificate_content.certificate_contacts << CertificateContact.new(contact.attributes)
          end
          cc = @certificate_order.certificate_content
        else
          cc.signing_request = @certificate_content.signing_request
          cc.server_software = @certificate_content.server_software
        end
        if cc.new?
          cc.submit_csr!
        elsif cc.validated? || cc.pending_validation?
          cc.pend_validation! if cc.validated?
          format.html { redirect_to(@certificate_order) }
        end
        format.html { redirect_to edit_certificate_order_url(@certificate_order) }
        format.xml  { head :ok }
      else
        @certificate = @certificate_order.certificate
        format.html { render '/certificates/buy', :layout=>'application' }
        format.xml  { render :xml => @certificate_order.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /certificate_orders/credits
  # GET /certificate_orders/credits.xml
  def credits
    p = {:page => params[:page]}
    @certificate_orders = (current_user.is_admin? ?
      CertificateOrder.all.find_all{|co|['paid'].include?(
        co.workflow_state && co.certificate_content.new?)} :
        current_user.ssl_account.certificate_orders.credits).paginate(p)

    respond_to do |format|
      format.html { render :action=>:index}
      format.xml  { render :xml => @certificate_orders }
    end
  end

  # GET /certificate_orders/credits
  # GET /certificate_orders/credits.xml
  def pending
    p = {:page => params[:page]}
    @certificate_orders = (current_user.is_admin? ?
      CertificateOrder.find_pending :
        current_user.ssl_account.certificate_orders.pending).paginate(p)

    respond_to do |format|
      format.html { render :action=>:index}
      format.xml  { render :xml => @certificate_orders }
    end
  end

  # GET /certificate_orders/credits
  # GET /certificate_orders/credits.xml
  def incomplete
    p = {:page => params[:page]}
    @certificate_orders = (current_user.is_admin? ?
      CertificateOrder.all(:include=>:certificate_contents).find_all{|co|
        next false unless co.certificate_content
        ['csr_submitted', 'info_provided', 'contacts_provided'].
        include?(co.certificate_content.workflow_state) &&
        !co.validation_rules_satisfied? && !co.expired?} :
      current_user.ssl_account.certificate_orders.incomplete).paginate(p)

    respond_to do |format|
      format.html { render :action=>:index}
      format.xml  { render :xml => @certificate_orders }
    end
  end

  # DELETE /certificate_orders/1
  # DELETE /certificate_orders/1.xml
  def destroy
    @certificate_order = CertificateOrder.find_by_ref(params[:id])
    @certificate_order.destroy

    respond_to do |format|
      format.html { redirect_to(certificate_orders_url) }
      format.xml  { head :ok }
    end
  end

  def download
    @certificate_order = CertificateOrder.find_by_ref(params[:id])
    t=@certificate_order.certificate_content.csr.signed_certificate.
      create_signed_cert_zip_bundle
    # End of the block  automatically closes the file.
    # Send it using the right mime type, with a download window and some nice file name.
    send_file t.path, :type => 'application/zip', :disposition => 'attachment',
      :filename => @certificate_order.friendly_common_name+'.zip'
    # The temp file will be deleted some time...
    t.close
  end

  def send_to_ca
    @certificate_order = CertificateOrder.find_by_ref(params[:id])
  end

  private

  def recert(action)
    instance_variable_set("@"+action,CertificateOrder.find_by_ref(params[:id]))
    instance_variable_get("@"+action)
  end

  def load_certificate_order
    @certificate_order=CertificateOrder.find_by_ref(params[:id])    
  end

  def setup_registrant
    unless @certificate_order.certificate_content.registrant.blank?
      @registrant = @certificate_order.certificate_content.registrant
    else
      @registrant = @certificate_order.certificate_content.build_registrant
    end
  end
end
