class CdnsController < ApplicationController
  include HTTParty
  before_action :set_cdn, only: [:show, :update, :destroy]

  # # GET /cdns
  # # GET /cdns.json
  def index
    #TODO: getting API Key from DB.
    api_key = '8f213487af4f47fc609590892cc292a91b48af0b'

    @results = {}
    @results[:api_key] = api_key

    if api_key
      @response = HTTParty.get('https://cdnify.com/api/v1/resources',
                               basic_auth: {username: api_key, password: 'x'})
      # @resources = JSON.parse(@response.body)
      # @results[:resources] = @resources
      @results[:resources] = @response.parsed_response['resources'] if @response.parsed_response
    end

    respond_to do |format|
      format.html { render :action => :index }
      format.xml { render :xml => @results }
    end
  end

  # GET /cdns/1
  # GET /cdns/1.json
  def show
    render json: @cdn
  end

  # POST /cdns
  # POST /cdns.json
  def create
    @cdn = Cdn.new(cdn_params)

    if @cdn.save
      render json: @cdn, status: :created, location: @cdn
    else
      render json: @cdn.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /cdns/1
  # PATCH/PUT /cdns/1.json
  def update
    if @cdn.update(cdn_params)
      head :no_content
    else
      render json: @cdn.errors, status: :unprocessable_entity
    end
  end

  # DELETE /cdns/1
  # DELETE /cdns/1.json
  def destroy
    @cdn.destroy

    head :no_content
  end

  private

    def set_cdn
      @cdn = Cdn.find(params[:id])
    end

    def cdn_params
      params.require(:cdn).permit()
    end
end
