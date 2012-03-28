class SiteChecksController < ApplicationController
  respond_to :xml, :json

  # GET /site_checks
  # GET /site_checks.xml
  def index
    @site_checks = SiteCheck.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @site_checks }
    end
  end

  # GET /site_checks/1
  # GET /site_checks/1.xml
  def show
    @site_check = SiteCheck.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @site_check }
    end
  end

  # GET /site_checks/new
  # GET /site_checks/new.xml
  def new
    @site_check = SiteCheck.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @site_check }
    end
  end

  # GET /site_checks/1/edit
  def edit
    @site_check = SiteCheck.find(params[:id])
  end

  # POST /site_checks
  # POST /site_checks.xml
  def create
    @site_checks=[]
    params[:urls].gsub(/\s+/, "").split(/[,\n]/).each do |url|
      @site_checks << SiteCheck.create(url: url)
    end
  end

  # PUT /site_checks/1
  # PUT /site_checks/1.xml
  def update
    @site_check = SiteCheck.find(params[:id])

    respond_to do |format|
      if @site_check.update_attributes(params[:site_checks])
        format.html { redirect_to(@site_check, :notice => 'Site check was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @site_check.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /site_checks/1
  # DELETE /site_checks/1.xml
  def destroy
    @site_check = SiteCheck.find(params[:id])
    @site_check.destroy

    respond_to do |format|
      format.html { redirect_to(site_checks_url) }
      format.xml  { head :ok }
    end
  end
end
