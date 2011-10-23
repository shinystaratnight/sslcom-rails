class SiteChecksController < ApplicationController
  # GET /site_checks
  # GET /site_checks.xml
  def index
    @site_checks = SiteChecker.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @site_checks }
    end
  end

  # GET /site_checks/1
  # GET /site_checks/1.xml
  def show
    @site_checker = SiteChecker.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @site_checker }
    end
  end

  # GET /site_checks/new
  # GET /site_checks/new.xml
  def new
    @site_checker = SiteChecker.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @site_checker }
    end
  end

  # GET /site_checks/1/edit
  def edit
    @site_checker = SiteChecker.find(params[:id])
  end

  # POST /site_checks
  # POST /site_checks.xml
  def create
    @site_checker = SiteChecker.new(params[:site_checker])

    respond_to do |format|
      if @site_checker.save
        format.html { redirect_to(@site_checker, :notice => 'Site checker was successfully created.') }
        format.xml  { render :xml => @site_checker, :status => :created, :location => @site_checker }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @site_checker.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /site_checks/1
  # PUT /site_checks/1.xml
  def update
    @site_checker = SiteChecker.find(params[:id])

    respond_to do |format|
      if @site_checker.update_attributes(params[:site_checker])
        format.html { redirect_to(@site_checker, :notice => 'Site checker was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @site_checker.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /site_checks/1
  # DELETE /site_checks/1.xml
  def destroy
    @site_checker = SiteChecker.find(params[:id])
    @site_checker.destroy

    respond_to do |format|
      format.html { redirect_to(site_checks_url) }
      format.xml  { head :ok }
    end
  end
end
