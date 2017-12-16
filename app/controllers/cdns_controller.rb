class CdnsController < ApplicationController
  include HTTParty
  before_action :set_cdn, only: [:show, :update, :destroy]
  before_action :require_user, only: [:index, :register_account, :register_api_key, :resource_setting]

  # # GET /cdns
  # # GET /cdns.json
  def index
    @results = {}
    if current_user.ssl_account
      cdn = Cdn.where(ssl_account_id: current_user.ssl_account.id).last

      if cdn
        @results[:api_key] = cdn.api_key

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

  def register_account
    if current_user.ssl_account
      reseller_api_key = 'b0434bb831ad83db23c5e5230800ca6ef4c7fa50c60a80ac17a6182cbe38cc2f'
      @response = HTTParty.post('https://reseller.cdnify.com/users',
                                {basic_auth: {username: reseller_api_key, password: 'x'}, body: {email: 'dev.soft3@gmail.com', password: 'Abcd12*34'}})

      # if @response.parsed_response
      #   if @response.parsed_response['resources']
      #     flash[:notice] = 'Successfully Added Custom Domain.'
      #   else
      #     @response.parsed_response['errors'].each do |error|
      #       msg = error['code'].to_s + ': ' + error['message']
      #       flash[:error] = msg
      #     end
      #   end
      # else
      #   flash[:error] = 'Failed to Add Custom Domain.'
      # end

      # TODO://API_KEY from reseller API.
      api_key = '8f213487af4f47fc609590892cc292a91b48af0b'

      cdn = Cdn.new
      cdn.api_key = api_key
      cdn.ssl_account_id = current_user.ssl_account.id
      cdn.save

      flash[:notice] = 'Successfully Registered Account.'
    else
      flash[:error] = 'Failed to Register Account.'
    end

    redirect_to cdns_path
  end

  def register_api_key
    if current_user.ssl_account
      cdn = Cdn.where(ssl_account_id: current_user.ssl_account.id).last
      cdn.api_key = params[:api_key]
      cdn.save

      flash[:notice] = 'Successfully Updated API Key.'
    else
      flash[:error] = 'Failed to Update API Key.'
    end

    redirect_to cdns_path
  end

  def add_custom_domain
    resource_id = params[:id]
    api_key = params[:api_key]
    custom_domains_list = []
    custom_domains_list << params[:custom_domain]

    # curl -X PATCH -u "8f213487af4f47fc609590892cc292a91b48af0b:x" https://cdnify.com/api/v1/resources/a080e67 -d alias=ssltst

    @response = HTTParty.patch('https://cdnify.com/api/v1/resources/' + resource_id + '/settings',
                               {basic_auth: {username: api_key, password: 'x'}, body: {custom_domains: custom_domains_list}})

    if @response.parsed_response
      if @response.parsed_response['resources']
        flash[:notice] = 'Successfully Added New Custom Domain.'
      else
        @response.parsed_response['errors'].each do |error|
          msg = error['code'].to_s + ': ' + error['message']
          flash[:error] = msg
        end
      end
    else
      flash[:error] = 'Failed to Add a New Custom Domain.'
    end

    redirect_to resource_setting_cdn_path(resource_id) and return
  end

  def update_advanced_setting
    resource_id = params[:id]
    api_key = params[:api_key]

    @response = HTTParty.patch('https://cdnify.com/api/v1/resources/' + resource_id + '/settings',
                               {basic_auth: {username: api_key, password: 'x'}, body: {
                                   allow_robots: !params[:allow_robots].blank?,
                                   cache_query_string: !params[:cache_query_string].blank?,
                                   enable_cors: !params[:enable_cors].blank?,
                                   disable_gzip: !params[:disable_gzip].blank?,
                                   force_ssl: !params[:pull_https].blank?,
                                   pull_https: !params[:pull_https].blank?,
                                   link: !params[:link].blank?
                               }})

    if @response.parsed_response
      if @response.parsed_response['resource']
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
    resource_id = params[:id]
    api_key = params[:api_key]
    resource_origin = params[:resource_origin]
    resource_name = params[:resource_name]

    @response = HTTParty.patch('https://cdnify.com/api/v1/resources/' + resource_id,
                               {basic_auth: {username: api_key, password: 'x'}, body: {alias: resource_name, origin: resource_origin}})

    if @response.parsed_response
      if @response.parsed_response['resources']
        flash[:notice] = 'Successfully Updated General Settings.'
      else
        @response.parsed_response['errors'].each do |error|
          msg = error['code'].to_s + ': ' + error['message']
          flash[:error] = msg
        end
      end
    else
      flash[:error] = 'Failed to Update General Settings.'
    end

    redirect_to resource_setting_cdn_path(resource_id) and return
  end

  def delete_resource
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
      flash[:notice] = 'Successfully Deleted Resource.'
    end

    redirect_to cdns_path
  end

  def update_resources
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
        flash[:notice] = 'Successfully Created Resource.'
      else
        @response.parsed_response['errors'].each do |error|
          msg = error['code'].to_s + ': ' + error['message']
          flash[:error] = msg
        end
      end
    else
      flash[:error] = 'Failed to Create Resource.'
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
end
