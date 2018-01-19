#ordering a certificate can be convoluted process because we wanted to maximize seo in the url and not
#necessarily follow proper REST. the flow is as follows:
#CertificatesController#buy
#OrdersController#new
#(or CertificateOrdersController#update_csr if unused credit)
#FundedAccount#allocate_funds or #confirm_funds if from funded_account (ie reseller)
#OrdersController#create_multi_free_ssl or OrdersController#create_free_ssl
#CertificateOrdersController#edit (goes to application info prompt) or OrdersController#edit or OrdersController#new
#CertificateOrdersController#update (goes to provide contacts prompt)
#CertificateContentsController#update if not express
#ValidationsController#new (asks for validation dcv and docs if not intranet/ucc, otherwise completes order)
#ValidationsController#upload
#
#order is sent to api in the pend_validation workflow transition in certificate_content
#OrderNotifier views contain all the email sent to customer during order

class CertificateOrdersController < ApplicationController
  layout 'application'
  include OrdersHelper
  skip_before_filter :verify_authenticity_token, only: [:parse_csr]
  before_filter :require_user,
                only: [:index, :credits, :show, :update, :edit, :download, :destroy, :update_csr, :auto_renew, :start_over,
                      :change_ext_order_number, :admin_update, :developer, :sslcom_ca]
  before_filter :load_certificate_order,
                only: [:show, :update, :edit, :download, :destroy, :update_csr, :auto_renew, :start_over,
                      :change_ext_order_number, :admin_update, :developer, :sslcom_ca]
  before_filter :set_row_page, only: [:index, :credits, :pending, :filter_by_scope, :order_by_csr, :filter_by,
                              :incomplete, :reprocessing]
  filter_access_to :all
  filter_access_to :read, :update, :delete, :show, :edit, :developer, attribute_check: true
  filter_access_to :incomplete, :pending, :search, :reprocessing, :order_by_csr, :require=>:read
  filter_access_to :credits, :filter_by, :filter_by_scope, :require=>:index
  filter_access_to :update_csr, require: [:update]
  filter_access_to :download, :start_over, :reprocess, :admin_update, :change_ext_order_number,
                   :developers, :require=>[:update, :delete]
  filter_access_to :renew, :parse_csr, require: [:create]
  filter_access_to :auto_renew, require: [:admin_manage]
  # filter_access_to :sslcom_ca, require: [:sysadmin_manage]
  #cache_sweeper :certificate_order_sweeper
  in_place_edit_for :certificate_order, :notes
  in_place_edit_for :csr, :signed_certificate_by_text

  NUM_ROWS_LIMIT=2

  def search
    index
  end

  # GET /certificate_orders
  # GET /certificate_orders.xml
  def index
#    expire_fragment('admin_header_certs_status') if
#      fragment_exist?('admin_header_certs_status')

    @certificate_orders = find_certificate_orders.paginate(@p)

    respond_to do |format|
      format.html { render :action => :index }
      format.xml  { render :xml => @certificate_orders }
    end
  end

  # GET /certificate_orders/1
  # GET /certificate_orders/1.xml
  def show
    redirect_to edit_certificate_order_path(@ssl_slug, @certificate_order) and return if @certificate_order.certificate_content.new?
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @certificate_order }
    end
  end

  def auto_renew
    action = CertificateOrder::RENEWING
    iv = recert(action)
    unless iv.blank?
      redirect_to buy_certificate_url(iv.renewal_certificate,
        {action.to_sym=>params[:id]})
    else
      not_found
    end
  end

  def sslcom_ca

  end

  def renew
    action = CertificateOrder::RENEWING
    iv = recert(action)
    unless iv.blank?
      redirect_to buy_renewal_certificate_url(iv.renewal_certificate,
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
      @certificate = @certificate_order.mapped_certificate
      unless @certificate.admin_submit_csr?
        if @certificate_order.is_unused_credit?
          @certificate_order.has_csr=true
          @certificate_content = @certificate_order.certificate_content
          @certificate_content.agreement=true
          return render '/certificates/buy', :layout=>'application'
        end
        unless @certificate_order.certificate_content.csr_submitted? or params[:registrant]
          redirect_to certificate_order_path(@ssl_slug, @certificate_order)
        else
          @csr = @certificate_order.certificate_content.csr
          setup_registrant()
          @registrant.company_name = @csr.organization
          @registrant.department = @csr.organization_unit
          @registrant.city = @csr.locality
          @registrant.state = @csr.state
          @registrant.email = @csr.email
          @registrant.country = @csr.country
        end
      else
        setup_registrant
      end
      @saved_registrants = current_user.ssl_account.saved_registrants
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
      domains = @certificate_order.all_domains
      @certificate_content = @certificate_order.certificate_contents.build(domains: domains,
                                         server_software_id: @certificate_order.certificate_content.server_software_id)
      # @certificate_content.additional_domains = domains
      #reset dcv validation
      @certificate_content.agreement=true
      @certificate_order.validation.validation_rules.each do |vr|
        if vr.description=~/\Adomain/
          ruling=@certificate_order.validation.validation_rulings.detect{|vrl| vrl.validation_rule == vr}
          ruling.pend! unless ruling.pending?
        end
      end
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
    @certificate = Certificate.for_sale.find_by_product(params[:certificate][:product])
    determine_eligibility_to_buy(@certificate, certificate_order)
    @certificate_order = Order.setup_certificate_order(certificate: @certificate, certificate_order: certificate_order)
    respond_to do |format|
      if @certificate_order.save
        if is_reseller? && (current_order.amount.cents >
              current_user.ssl_account.funded_account.amount.cents)
          format.html {redirect_to allocate_funds_for_order_path(:id=>
                'certificate')}
        else
          format.html {redirect_to confirm_funds_path(:id=>'certificate_order')}
        end
      else
        format.html { render(:template => "certificates/buy")}
      end
    end
  end

  # PUT /certificate_orders/1
  # PUT /certificate_orders/1.xml
  def update
    respond_to do |format|
      if @certificate_order.update_attributes(params[:certificate_order])
        cc = @certificate_order.certificate_content
        if cc.csr_submitted? or cc.new?
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
              c.country = Country.find_by_name_caps(r.country.upcase).iso1_code if
                  Country.find_by_name_caps(r.country.upcase)
              c.clear_roles
              c.add_role! role
              cc.certificate_contacts << c
              cc.update_attribute(role+"_checkbox", true) unless
                role==CertificateContent::ADMINISTRATIVE_ROLE
            end
            unless @certificate_order.certificate.is_ev?
              cc.provide_contacts!
            end
          end
        end
        if @certificate_order.is_express_signup?
          format.html { redirect_to validation_destination(slug: @ssl_slug, certificate_order: @certificate_order) }
        else #assume ev full signup process
          format.html { redirect_to certificate_content_contacts_path(@ssl_slug, cc) }
        end
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
    @certificate_content=CertificateContent.new(
      params[:certificate_order][:certificate_contents_attributes]['0'.to_sym]
        .merge(rekey_certificate: true)
    )
    @certificate_order.has_csr=true #we are submitting a csr afterall
    @certificate_content.certificate_order=@certificate_order
    @certificate_content.preferred_reprocessing=true if eval("@#{CertificateOrder::REPROCESSING}")

    respond_to do |format|
      if @certificate_content.valid?
        cc = @certificate_order.transfer_certificate_content(@certificate_content)
        if cc.pending_validation?
          format.html { redirect_to certificate_order_path(@ssl_slug, @certificate_order) }
        end
        format.html { redirect_to edit_certificate_order_path(@ssl_slug, @certificate_order) }
        format.xml  { head :ok }
      else
        @certificate = @certificate_order.certificate
        format.html { render '/certificates/buy', :layout=>'application' }
        format.xml  { render :xml => @certificate_order.errors, :status => :unprocessable_entity }
      end
    end
  end

  def change_ext_order_number
    @certificate_order.update_column :external_order_number, params[:num]
    SystemAudit.create(owner: current_user, target: @certificate_order,
                       action: "changed external order number to #{params[:num]}")
    redirect_to certificate_order_path(@ssl_slug, @certificate_order)
  end

  # GET /certificate_orders/credits
  # GET /certificate_orders/credits.xml
  def credits
    @certificate_orders = (current_user.is_admin? ?
      CertificateOrder.where{(workflow_state=='paid') & (certificate_contents.workflow_state == "new")} :
        current_user.ssl_account.certificate_orders.credits).paginate(@p)

    respond_to do |format|
      format.html { render :action=>:index}
      format.xml  { render :xml => @certificate_orders }
    end
  end

  def pending
    @certificate_orders = (current_user.is_admin? ?
      CertificateOrder.pending :
        current_user.ssl_account.certificate_orders.pending).paginate(@p)

    respond_to do |format|
      format.html { render :action=>:index}
      format.xml  { render :xml => @certificate_orders }
    end
  end

  def filter_by_scope
    @certificate_orders = (current_user.is_admin? ?
      CertificateOrder.send(params[:id].to_sym) :
        current_user.ssl_account.certificate_orders.send(params[:id].to_sym)).paginate(@p)

    respond_to do |format|
      format.html { render :action=>:index}
      format.xml  { render :xml => @certificate_orders }
    end
  end

  def order_by_csr
    @certificate_orders = (current_user.is_admin? ?
      CertificateOrder.unscoped{CertificateOrder.not_test} :
        current_user.ssl_account.certificate_orders.unscoped{
          current_user.ssl_account.certificate_orders.not_test}).order_by_csr.paginate(@p)

    respond_to do |format|
      format.html { render :action=>:index}
      format.xml  { render :xml => @certificate_orders }
    end
  end

  def filter_by
    
    @certificate_orders = current_user.is_admin? ?
        (@ssl_account.try(:certificate_orders) || CertificateOrder) : current_user.ssl_account.certificate_orders
    @certificate_orders = @certificate_orders.not_test.not_new.filter_by(params[:id]).paginate(@p)

    respond_to do |format|
      format.html { render :action=>:index}
      format.xml  { render :xml => @certificate_orders }
    end
  end

  # GET /certificate_orders/credits
  # GET /certificate_orders/credits.xml
  def incomplete
    @certificate_orders = (current_user.is_admin? ?
      CertificateOrder.incomplete :
      current_user.ssl_account.certificate_orders.incomplete).paginate(@p)

    respond_to do |format|
      format.html { render :action=>:index}
      format.xml  { render :xml => @certificate_orders }
    end
  end

  # GET /certificate_orders/credits
  # GET /certificate_orders/credits.xml
  def reprocessing
    @certificate_orders = (current_user.is_admin? ?
      CertificateOrder.reprocessing :
      current_user.ssl_account.certificate_orders.reprocessing).paginate(@p)

    respond_to do |format|
      format.html { render :action=>:index}
      format.xml  { render :xml => @certificate_orders }
    end
  end

  # DELETE /certificate_orders/1
  # DELETE /certificate_orders/1.xml
  def destroy
    @certificate_order.destroy

    respond_to do |format|
      format.html { redirect_to(certificate_orders_url) }
      format.xml  { head :ok }
    end
  end

  def developer

  end

  def developers
    not_found and return unless is_sandbox?
  end

  def download
    t=File.new(@certificate_order.certificate_content.csr.signed_certificate.
      create_signed_cert_zip_bundle({components: true, is_windows: is_client_windows?}), "r")
    # End of the block  automatically closes the file.
    # Send it using the right mime type, with a download window and some nice file name.
    send_file t.path, :type => 'application/zip', :disposition => 'attachment',
      :filename => @certificate_order.friendly_common_name+'.zip'
    # The temp file will be deleted some time...
    t.close
  end

  def download_other
    t=File.new(@certificate_order.certificate_content.csr.signed_certificate.
      create_signed_cert_zip_bundle(is_windows: is_client_windows?), "r")
    # End of the block  automatically closes the file.
    # Send it using the right mime type, with a download window and some nice file name.
    send_file t.path, :type => 'application/zip', :disposition => 'attachment',
      :filename => @certificate_order.friendly_common_name+'.zip'
    # The temp file will be deleted some time...
    t.close
  end

  # this function allows the customer to resubmit a new csr even while the order is being processed
  def start_over
    @certificate_order.start_over! unless @certificate_order.blank?
    flash[:notice] = "certificate order #{@certificate_order.ref} has been canceled and restarted"
  end

  def parse_csr
    c=Certificate.for_sale.find_by_product(params[:certificate])
    co=CertificateOrder.new(duration: 1)
    @cc=co.certificate_contents.build(certificate_order: co, ajax_check_csr: true)
    co=Order.setup_certificate_order(certificate: c, certificate_order: co)
    @cc.csr=Csr.new(body: params[:csr])
    @cc.valid?
    rescue
  end

  def admin_update
    respond_to do |format|
      if @certificate_order.update_attributes(params[:certificate_order])
        format.js { render :json=>@certificate_order.to_json}
      else
        format.js { render :json=>@certificate_order.errors.to_json}
      end
    end
  end

  private
  def set_row_page
    preferred_row_count = current_user.preferred_cer_order_row_count
    @per_page = params[:per_page] || preferred_row_count.or_else("10")
    CertificateOrder.per_page = @per_page if CertificateOrder.per_page != @per_page

    if @per_page != preferred_row_count
      current_user.preferred_cer_order_row_count = @per_page
      current_user.save
    end

    @p = {page: (params[:page] || 1), per_page: @per_page}
  end

  def recert(action)
    instance_variable_set("@"+action,CertificateOrder.find_by_ref(params[:id]))
    instance_variable_get("@"+action)
  end

  def load_certificate_order
    @certificate_order=CertificateOrder.unscoped{
      (current_user.is_system_admins? ? CertificateOrder :
              current_user.ssl_account.certificate_orders).find_by_ref(params[:id])} if current_user
    render :text => "404 Not Found", :status => 404 unless @certificate_order
  end

  def setup_registrant
    unless @certificate_order.certificate_content.registrant.blank?
      @registrant = @certificate_order.certificate_content.registrant
    else
      @registrant = @certificate_order.certificate_content.build_registrant
    end
  end
end
