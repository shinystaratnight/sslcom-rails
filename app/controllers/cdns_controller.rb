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
    unless current_user.ssl_account.blank?
      cdn = Cdn.where(ssl_account_id: current_user.ssl_account.id).last

      if cdn
        @results[:api_key] = cdn.api_key
        @results[:used_resource] = cdn.host_name

        @response = HTTParty.get('https://cdnify.com/api/v1/resources',
                                 basic_auth: {username: cdn.api_key, password: 'x'})
        @results[:resources] = @response.parsed_response['resources'] if @response.parsed_response
      end
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

    if current_user.ssl_account.blank?
      flash[:error] = 'Failed to register API Key.'
    else
      cdn = Cdn.where(ssl_account_id: current_user.ssl_account.id).last
      if cdn
        cdn.api_key = params[:api_key]
        cdn.host_name = ''
      else
        cdn = Cdn.new
        cdn.api_key = params[:api_key]
        cdn.ssl_account_id = current_user.ssl_account.id
      end
      cdn.save

      flash[:notice] = 'Successfully Registered API Key.'
    end

    redirect_to cdns_path
  end

  def add_custom_domain
    if current_user.blank?
      redirect_to login_url and return
    end

    resource_id = params[:id]
    api_key = params[:api_key]
    custom_domain = params[:custom_domain]

    @response = HTTParty.patch('https://cdnify.com/api/v1/resources/' + resource_id,
                               {basic_auth: {username: api_key, password: 'x'}, body: {custom_domains: custom_domain}})

    if @response.parsed_response
      if @response.parsed_response['resources']
        flash[:notice] = 'Successfully Added Custom Domain.'
      else
        @response.parsed_response['errors'].each do |error|
          msg = error['code'].to_s + ': ' + error['message']
          flash[:error] = msg
        end
      end
    else
      flash[:error] = 'Failed to Add Custom Domain.'
    end

    redirect_to resource_setting_cdn_path(resource_id) and return
  end

  def update_advanced_setting
    if current_user.blank?
      redirect_to login_url and return
    end

    resource_id = params[:id]
    api_key = params[:api_key]
    advanced_settings = {}
    advanced_settings['allow_robots'] = params[:allow_robots]
    advanced_settings['cache_query_str'] = params[:cache_query_str]
    advanced_settings['enable_cors'] = params[:enable_cors]
    advanced_settings['disable_gzip'] = params[:disable_gzip]
    advanced_settings['force_ssl'] = params[:force_ssl]
    advanced_settings['pull_https'] = params[:pull_https]
    advanced_settings['link'] = params[:link]

    @response = HTTParty.patch('https://cdnify.com/api/v1/resources/' + resource_id,
                               {basic_auth: {username: api_key, password: 'x'}, body: {advanced_settings: advanced_settings}})

    if @response.parsed_response
      if @response.parsed_response['resources']
        flash[:notice] = 'Successfully Updated Advanced Settings.'
      else
        @response.parsed_response['errors'].each do |error|
          msg = error['code'].to_s + ': ' + error['message']
          flash[:error] = msg
        end
      end
    else
      flash[:error] = 'Failed to Update Advanced Settings.'
    end

    redirect_to resource_setting_cdn_path(resource_id) and return
  end

  def update_resource
    if current_user.blank?
      redirect_to login_url and return
    end

    resource_id = params[:id]
    api_key = params[:api_key]
    resource_origin = params[:resource_origin]
    resource_name = params[:resource_name]

    @response = HTTParty.patch('https://cdnify.com/api/v1/resources/' + resource_id,
                               {basic_auth: {username: api_key, password: 'x'}, body: {alias: resource_name, origin: resource_origin}})

    if @response.parsed_response
      if @response.parsed_response['resources']
        flash[:notice] = 'Successfully Updated Resource Information.'
      else
        @response.parsed_response['errors'].each do |error|
          msg = error['code'].to_s + ': ' + error['message']
          flash[:error] = msg
        end
      end
    else
      flash[:error] = 'Failed to Update.'
    end

    redirect_to resource_setting_cdn_path(resource_id) and return
  end

  def delete_resource
    if current_user.blank?
      redirect_to login_url and return
    end

    resource_id = params[:id]
    api_key = params[:api_key]

    @response = HTTParty.delete('https://cdnify.com/api/v1/resources/' + resource_id,
                                basic_auth: {username: api_key, password: 'x'})

    if @response.parsed_response
      @response.parsed_response['errors'].each do |error|
        msg = error['code'].to_s + ': ' + error['message']
        flash[:error] = msg
      end

      redirect_to resource_setting_cdn_path(resource_id) and return
    else
      flash[:notice] = 'Successfully Deleted.'
    end

    redirect_to cdns_path
  end

  def update_resources
    if current_user.blank?
      redirect_to login_url and return
    end

    resources = params['deleted_resources']
    is_deleted = true

    if resources
      resources.each do |resource_id|
        @response = HTTParty.delete('https://cdnify.com/api/v1/resources/' + resource_id,
                                 basic_auth: {username: params['api_key'], password: 'x'})
        if @response.parsed_response
          is_deleted = false
          @response.parsed_response['errors'].each do |error|
            msg = error['code'].to_s + ': ' + error['message']
            flash[:error] = msg
          end
        end
      end
    end

    if is_deleted
      flash[:notice] = 'Successfully Updated.'
    end

    redirect_to cdns_path
  end

  def resource_setting
    resource_id = params['id']

    @results = {}
    unless current_user.ssl_account.blank?
      cdn = Cdn.where(ssl_account_id: current_user.ssl_account.id).last

      if cdn
        @results[:api_key] = cdn.api_key
        @response = HTTParty.get('https://cdnify.com/api/v1/resources/' + resource_id,
                                 basic_auth: {username: cdn.api_key, password: 'x'})
        @results[:resource] = @response.parsed_response['resources'][0] if @response.parsed_response
      end
    end

    respond_to do |format|
      format.html { render :action => "resource_setting" }
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
