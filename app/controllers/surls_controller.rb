class SurlsController < ApplicationController
  # GET /surls
  # GET /surls.xml
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @surls }
    end
  end

  # GET /surls/1
  # GET /surls/1.xml
  def show
    @surl = Surl.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @surl }
    end
  end

  # GET /surls/new
  # GET /surls/new.xml
  def new
    @surl = Surl.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @surl }
    end
  end

  # GET /surls/1/edit
  def edit
    @surl = Surl.find(params[:id])
  end

  # POST /surls
  # POST /surls.xml
  def create
    @surl = Surl.new(params[:surl])

    respond_to do |format|
      if @surl.save
        format.html { redirect_to(@surl, :notice => 'Surl was successfully created.') }
        format.xml  { render :xml => @surl, :status => :created, :location => @surl }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @surl.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /surls/1
  # PUT /surls/1.xml
  def update
    @surl = Surl.find(params[:id])

    respond_to do |format|
      if @surl.update_attributes(params[:surl])
        format.html { redirect_to(@surl, :notice => 'Surl was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @surl.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /surls/1
  # DELETE /surls/1.xml
  def destroy
    @surl = Surl.find(params[:id])
    @surl.destroy

    respond_to do |format|
      format.html { redirect_to(surls_url) }
      format.xml  { head :ok }
    end
  end
end
