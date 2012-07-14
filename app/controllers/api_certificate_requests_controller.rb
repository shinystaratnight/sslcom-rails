class ApiCertificateRequestsController < ApplicationController
  before_filter :set_test
  skip_filter :identify_visitor, :record_visit

  wrap_parameters ApiCertificateRequest, include:
      [*(ApiCertificateRequest::ACCESSORS+
          ApiCertificateRequest::RETRIEVE_ACCESSORS+
          ApiCertificateRequest::DCV_EMAILS_ACCESSORS).uniq]
  respond_to :xml, :json

  TEST_SUBDOMAIN = "sws-test"

  # GET /apis
  # GET /apis.xml
  def index
    @apis = Api.all
    respond_with @apis
  end

  def show
    @api = Api.find(params[:id])
    respond_with @api
  end

  # GET /apis/new
  # GET /apis/new.xml
  def new
    @api = Api.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @api }
    end
  end

  # GET /apis/1/edit
  def edit
    @api = Api.find(params[:id])
  end

  # POST /certificates/create
  # POST /certificates/create.xml
  def create
    @api = Api.create(params[:api])
    respond_with @api
  end

  # PUT /apis/1
  # PUT /apis/1.xml
  def update
    @api = Api.find(params[:id])

    respond_to do |format|
      if @api.update_attributes(params[:api])
        format.html { redirect_to(@api, :notice => 'Api was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @api.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /apis/1
  # DELETE /apis/1.xml
  def destroy
    @api = Api.find(params[:id])
    @api.destroy

    respond_to do |format|
      format.html { redirect_to(apis_url) }
      format.xml  { head :ok }
    end
  end

  def create_v1_3
    @result = ApiCertificateCreate.new(params[:api_certificate_request])
    @result.test = @test
    if @result.csr_obj && !@result.csr_obj.valid?
      # we do this sloppy maneuver because the rabl template only reports errors
      @result = @result.csr_obj
    else
      if @result.save
        if @acr = @result.create_certificate_order
          # successfully charged
          if @acr.errors.empty?
            @result.ref = @acr.ref
            @result.order_status = "pending validation"
            @result.order_amount = @acr.order.amount.format
            @result.certificate_url = url_for(@acr)
            @result.receipt_url = url_for(@acr.order)
            @result.smart_seal_url = certificate_order_site_seal_url(@acr)
            @result.validation_url = certificate_order_validation_url(@acr)
            render(:template => "api_certificate_requests/success_create_v1_3")
          else
            @result = @acr #so that rabl can report errors
          end
        end
      else
        InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
      end
    end
  end

  def retrieve_v1_3
    @result = ApiCertificateRetrieve.new(params[:api_certificate_request])
    @result.test = @test
    if @result.save
      @certificate_order = CertificateOrder.find_by_ref(@result.ref)
      render(:template => "api_certificate_requests/success_retrieve_v1_3") and return
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
    end
    render action: :create_v1_3
  end

  def dcv_emails_v1_3
    @result=ApiDcvEmails.new(params[:api_certificate_request])
    @result.test = @test
    if @result.save
      @result.email_addresses=ComodoApi.domain_control_email_choices(@result.domain_name).email_address_choices
      unless @result.email_addresses.blank?
        render(:template => "api_certificate_requests/success_dcv_emails_v1_3") and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
    end
    render action: :create_v1_3
  end

  private

  def set_test
    @test = (current_subdomain==TEST_SUBDOMAIN) ? true : false
  end
end
