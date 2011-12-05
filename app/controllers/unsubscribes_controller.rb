class UnsubscribesController < ApplicationController
  # GET /unsubscribes
  # GET /unsubscribes.xml
  def index
    @unsubscribes = Unsubscribe.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @unsubscribes }
    end
  end

  # GET /unsubscribes/1
  # GET /unsubscribes/1.xml
  def show
    @unsubscribe = Unsubscribe.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @unsubscribe }
    end
  end

  # GET /unsubscribes/new
  # GET /unsubscribes/new.xml
  def new
    @unsubscribe = Unsubscribe.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @unsubscribe }
    end
  end

  # GET /unsubscribes/1/edit
  def edit
    @unsubscribe = Unsubscribe.find_by_ref(params[:id])
    @unsubscribe.enforce=true
  end

  # POST /unsubscribes
  # POST /unsubscribes.xml
  def create
    @unsubscribe = Unsubscribe.new(params[:unsubscribe])

    respond_to do |format|
      if @unsubscribe.save
        format.html { redirect_to(@unsubscribe, :notice => 'Unsubscribe was successfully created.') }
        format.xml  { render :xml => @unsubscribe, :status => :created, :location => @unsubscribe }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @unsubscribe.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /unsubscribes/1
  # PUT /unsubscribes/1.xml
  def update
    @unsubscribe = Unsubscribe.find(params[:id])
    if params[:email]==@unsubscribe.email
      @unsubscribe.update_attributes(params[:unsubscribe])
    else
      @unsubscribe.errors[:base] << "test"
    end

    respond_to do |format|
      format.js {render(text: (@unsubscribe.errors.blank? && !@unsubscribe.new_record?) ?
        @unsubscribe.to_json : @unsubscribe.errors.to_json)}
    end
  end

  # DELETE /unsubscribes/1
  # DELETE /unsubscribes/1.xml
  def destroy
    @unsubscribe = Unsubscribe.find(params[:id])
    @unsubscribe.destroy

    respond_to do |format|
      format.html { redirect_to(unsubscribes_url) }
      format.xml  { head :ok }
    end
  end
end
