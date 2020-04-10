class SiteSealsController < ApplicationController
  layout 'application'
  before_action :find_site_seal, only: [:artifacts, :site_report, :edit, :update, :admin_update]
  filter_access_to :all
  filter_access_to :edit, :update, :admin_update, attribute_check: true
  filter_access_to :artifacts, :details, :require=>:read

  def search
    index
    render action: :index
  end

  # GET /site_seals
  # GET /site_seals.xml
  def index
    p = {:page => params[:page]}
    @certificate_orders = find_certificate_orders.joins(:site_seal).
        select('distinct certificate_orders.*').
        where("site_seals.workflow_state NOT IN ('new', 'canceled', 'deactivated')").paginate(p)
#    @site_seals = find_certificate_orders(includes: :site_seal).
#      map(&:site_seal).uniq.select{|ss|!ss.is_disabled?}.paginate(p)
  end

  # GET /site_seals/1
  # GET /site_seals/1.xml
  def show
    @certificate_order = CertificateOrder.unscoped.includes(:site_seal).find_by_ref(params[:certificate_order_id])
    @site_seal = @certificate_order.site_seal

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @site_seal }
    end
  end

  # GET /site_seals/new
  # GET /site_seals/new.xml
  def new
    @site_seal = SiteSeal.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @site_seal }
    end
  end

  # POST /site_seals
  # POST /site_seals.xml
  def create
    @site_seal = SiteSeal.new(params[:site_seal])

    respond_to do |format|
      if @site_seal.save
        flash[:notice] = 'SiteSeal was successfully created.'
        format.html { redirect_to(@site_seal) }
        format.xml  { render :xml => @site_seal, :status => :created, :location => @site_seal }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @site_seal.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /site_seals/1
  # PUT /site_seals/1.xml
  def update
    respond_to do |format|
      if @site_seal.update_attributes(params[:site_seal])
        format.html { redirect_to(@site_seal) }
        format.js   { render :json=>@site_seal.to_json}
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @site_seal.errors, :status => :unprocessable_entity }
        format.js   { render :json=> @site_seal.errors.to_json}
      end
    end
  end

  def admin_update
    @co = CertificateOrder.find params[:certificate_order]
    respond_to do |format|
      #allows us to bypass attr_protected. note this is admin only function
      @site_seal.assign_attributes params[:site_seal], without_protection: true
      if @site_seal.save
        notify_customer if params[:email_customer]
        format.html { redirect_to(@site_seal) }
        format.js   { render :json=>@site_seal.to_json}
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @site_seal.errors, :status => :unprocessable_entity }
        format.js   { render :json=> @site_seal.errors.to_json}
      end
    end
  end

  def site_report
    if @site_seal.blank? || @site_seal.is_disabled?
      render :disabled, :layout=>"site_report"
    else
      render :site_report, :layout=>"site_report"
    end
  end

  def artifacts
    unless @site_seal.is_disabled?
      render :artifacts, :layout=>"site_report"
    else
      render :disabled, :layout=>"site_report"
    end
  end

  private

  def notify_customer
    @co.processed_recipients.map{|r|r.split(" ")}.flatten.uniq.each do |c|
      if @site_seal.fully_activated?
        OrderNotifier.site_seal_approve(c, @co).deliver if @co.certificate.is_server?
      else
        OrderNotifier.site_seal_unapprove(c, @co).deliver
      end
    end
  end

  def find_site_seal
    @site_seal = SiteSeal.find_by_ref(params[:id])
  end

end
