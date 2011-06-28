class SurlsController < ApplicationController

  # GET /surls
  # GET /surls.xml
  def index
    @surl = Surl.new
  end

  # GET /surls/1
  # GET /surls/1.xml
  def show
    @surl = Surl.find(params[:id].to_i(36))
  end

  # GET /surls/new
  # GET /surls/new.xml
  def new
    @surl = Surl.new
  end

  # GET /surls/1/edit
  def edit
    @surl = Surl.find(params[:id])
  end

  # POST /surls
  # POST /surls.xml
  def create
    @surl = Surl.create(params[:surl])
    respond_to do |format|
      format.js {render(text: @surl.to_json)}
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
