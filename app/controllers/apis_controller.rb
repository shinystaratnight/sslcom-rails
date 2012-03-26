class ApisController < ApplicationController
  respond_to :xml, :json

  SUBDOMAIN = "sws"

  # GET /apis
  # GET /apis.xml
  def index
    @apis = Api.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @apis }
    end
  end

  # GET /apis/1
  # GET /apis/1.xml
  def show
    @api = Api.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @api }
    end
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
  def create_certificate
    @co = CertificateOrder.last
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

  def create_certificate_order
    @co = CertificateOrder.new
  end
end
