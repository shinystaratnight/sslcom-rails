class CdnsController < ApplicationController
  include HTTParty
  before_action :set_cdn, only: [:show, :update, :destroy]

  # # GET /cdns
  # # GET /cdns.json
  def index
    if current_user.blank?
      redirect_to login_url and return
    end

    @results = {}
    cdn = Cdn.where(user_id: current_user.id).last

    if cdn
      @results[:api_key] = cdn.api_key
      @results[:used_resource] = cdn.host_name

      @response = HTTParty.get('https://cdnify.com/api/v1/resources',
                               basic_auth: {username: cdn.api_key, password: 'x'})
      @results[:resources] = @response.parsed_response['resources'] if @response.parsed_response
    end

    respond_to do |format|
      format.html { render :action => :index }
      format.xml { render :xml => @results }
    end
  end

  def register_api_key
    if current_user.blank?
      redirect_to login_url and return
    end

    cdn = Cdn.where(user_id: current_user.id).last
    if cdn
      cdn.api_key = params[:api_key]
      cdn.host_name = ''
    else
      cdn = Cdn.new
      cdn.api_key = params[:api_key]
      cdn.user_id = current_user.id
    end
    cdn.save

    flash[:notice] = 'Successfully Registered API Key.'
    redirect_to cdns_path
  end

  def update_resources
    if current_user.blank?
      redirect_to login_url and return
    end

    resources = params['deleted_resources']
    used_resource = params['used_resources']
    delete_used_resource = false

    is_deleted = true
    is_saved = true

    if resources
      resources.each do |resource_id|
        @response = HTTParty.delete('https://cdnify.com/api/v1/resources/' + resource_id,
                                 basic_auth: {username: params['api_key'], password: 'x'})
        if @response.parsed_response
          is_deleted = false
        else
          if used_resource
            delete_used_resource = used_resource[0..(used_resource.index('|')-1)] == resource_id
          end
        end
      end
    end

    if used_resource
      cdn = Cdn.where(user_id: current_user.id).last

      if cdn
        if delete_used_resource
          cdn.host_name = ''
        else
          cdn.host_name = used_resource[(used_resource.index('|') + 1)..(used_resource.length)]
        end

        cdn.save
      else
        is_saved = false
      end
    end

    if is_deleted && is_saved
      flash[:notice] = 'Successfully Updated.'
    else
      flash[:error] = 'Failed to Update.'
    end

    redirect_to cdns_path
  end

  # GET /cdns/1
  # GET /cdns/1.json
  def show
    render json: @cdn
  end

  # POST /cdns
  # POST /cdns.json
  def create
    api_key = params[:api_key]
    resource_name = params[:resource_name]
    resource_origin = params[:resource_origin]

    @response = HTTParty.post('https://cdnify.com/api/v1/resources',
                             {basic_auth: {username: api_key, password: 'x'}, body: {alias: resource_name, origin: resource_origin}})

    if @response.parsed_response
      if @response.parsed_response['resources']
        flash[:notice] = 'Successfully Created.'
      else
        @response.parsed_response['errors'].each do |error|
          msg = error['code'].to_s + ': ' + error['message']
          flash[:error] = msg
        end
      end
    else
      flash[:error] = 'Failed to Create.'
    end

    redirect_to cdns_path
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

    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.user
    end
end
