class ApiCertificateRequestsController < ApplicationController
  skip_filter :identify_visitor, :record_visit

  wrap_parameters ApiCertificateRequest, include: [*ApiCertificateRequest::ACCESSORS]
  respond_to :xml, :json

  SUBDOMAIN = "sws"

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
    @result = @acr = ApiCertificateRequest.new(params[:api_certificate_request])
    unless @acr.csr_obj.valid?
      # we do this sloppy maneuver because the rabl template only reports errors
      @result = @acr.csr_obj
    else
      if @acr.save
        if @result = @acr.create_certificate_order
          # successfully charged
          if @result.errors.empty?
            @result.certificate_url = url_for(@result)
            @result.receipt_url = url_for(@result.order)
            @result.smart_seal_url = certificate_order_site_seal_url(@result)
            @result.validation_url = certificate_order_validation_url(@result)
            render(:template => "api_certificate_requests/success_create_v1_3")
          end
        end
      else
        InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
      end
    end
    #respond_with @acr
  end
end
