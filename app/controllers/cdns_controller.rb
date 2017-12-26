class CdnsController < ApplicationController
  include HTTParty
  before_action :set_cdn, only: [:show, :update, :destroy]
  before_action :require_user, only: [:index, :register_account, :register_api_key, :resource_setting, :resource_cache]

  # # GET /cdns
  # # GET /cdns.json
  def index
    @results = {}
    @results[:is_admin] = current_user.is_system_admins?

    if current_user.ssl_account
      cdn = Cdn.where(ssl_account_id: current_user.ssl_account.id).last
      # cdn = Cdn.where(ssl_account_id: '111').last

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

  def add_custom_domain
    resource_id = params[:id]
    api_key = params[:api_key]
    custom_domain = params[:custom_domain]

    @response = HTTParty.post('https://cdnify.com/api/v1/resources/' + resource_id + '/custom_domains',
                              {basic_auth: {username: api_key, password: 'x'}, body: {hostname: custom_domain}})

    # certificate_value = params['certificate_value']
    # private_key = params['private_key']
    # byebug
    # @response = HTTParty.post('https://cdnify.com/api/v1/resources/' + resource_id + '/custom_domains',
    #                           {basic_auth: {username: api_key, password: 'x'},
    #                            body: {hostname: custom_domain, certificates: {certificate: certificate_value, privateKey: private_key}}})

    if @response.parsed_response
      if @response.parsed_response['errors']
        @response.parsed_response['errors'].each do |error|
          msg = error['code'].to_s + ': ' + error['message']
          flash[:error] = msg
        end
      else
        flash[:notice] = @response.parsed_response['message']
      end
    else
      flash[:error] = 'Failed to Add a New Custom Domain.'
    end

    redirect_to resource_setting_cdn_path(resource_id) and return
  end

  def update_custom_domain
    resource_id = params[:id]
    action_type = params['action_type']
    api_key = params['api_key']
    host_name = params['host_name']

    if action_type == 'modify'
      certificate_value = params['certificate_value']
      private_key = params['private_key']

      @response = HTTParty.post('https://cdnify.com/api/v1/resources/' + resource_id + '/custom_domains',
                                {basic_auth: {username: api_key, password: 'x'},
                                 body: {hostname: host_name, certificates: {certificate: certificate_value, privateKey: private_key}}})

      if @response.parsed_response && @response.parsed_response['errors']
        @response.parsed_response['errors'].each do |error|
          msg = error['code'].to_s + ': ' + error['message']
          flash[:error] = msg
        end
      else
        flash[:notice] = @response.parsed_response && @response.parsed_response['message'] ?
                             @response.parsed_response['message'] : 'Successfully Modified.'
      end
    else
      @response = HTTParty.delete('https://cdnify.com/api/v1/resources/' + resource_id + '/custom_domains/' + host_name,
                                  basic_auth: {username: api_key, password: 'x'})

      if @response.parsed_response
        if @response.parsed_response['errors']
          @response.parsed_response['errors'].each do |error|
            msg = error['code'].to_s + ': ' + error['message']
            flash[:error] = msg
          end
        end
      else
        flash[:notice] = 'Successfully Deleted.'
      end
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

  def resource_cache
    resource_id = params['id']
    @results = {}

    unless current_user.ssl_account.blank?
      cdn = Cdn.where(ssl_account_id: current_user.ssl_account.id).last

      if cdn
        @results[:api_key] = cdn.api_key
        @response = HTTParty.get('https://cdnify.com/api/v1/resources/' + resource_id,
                                 basic_auth: {username: cdn.api_key, password: 'x'})
        @results[:expire_time] = @response.parsed_response['resources'][0]['advanced_settings']['cache_expire_time'] if @response.parsed_response

        @response = HTTParty.get('https://cdnify.com/api/v1/resources/' + resource_id + '/cache',
                                 basic_auth: {username: cdn.api_key, password: 'x'})
        @results[:files] = @response.parsed_response['files'] if @response.parsed_response && @response.parsed_response['files']
      end
    end

    respond_to do |format|
      format.html { render :action => "resource_cache" }
      format.xml { render :xml => @results }
    end
  end

  def purge_cache
    resource_id = params[:id]
    api_key = params[:api_key]
    files = params[:purge_files].split(',')
    is_purge_all = params[:purge_all]

    if is_purge_all == 'true'
      @response = HTTParty.delete('https://cdnify.com/api/v1/resources/' + resource_id + '/cache',
                                  basic_auth: {username: api_key, password: 'x'})
    else
      @response = HTTParty.delete('https://cdnify.com/api/v1/resources/' + resource_id + '/cache',
                                  {basic_auth: {username: api_key, password: 'x'}, body: {files: files}})
    end

    if @response.parsed_response
      @response.parsed_response['errors'].each do |error|
        msg = error['code'].to_s + ': ' + error['message']
        flash[:error] = msg
      end
    else
      flash[:notice] = 'Successfully Purged File(s).'
    end

    redirect_to resource_cache_cdn_path(resource_id) and return
  end

  def update_cache_expiry
    resource_id = params[:id]
    api_key = params[:api_key]

    @response = HTTParty.patch('https://cdnify.com/api/v1/resources/' + resource_id + '/settings',
                               {basic_auth: {username: api_key, password: 'x'}, body: {cache_expire_time: params[:expiry_hours]}})

    if @response.parsed_response
      if @response.parsed_response['resource']
        flash[:notice] = 'Successfully Updated Cache Expire Time.'
      else
        @response.parsed_response['errors'].each do |error|
          msg = error['code'].to_s + ': ' + error['message']
          flash[:error] = msg
        end
      end
    else
      flash[:error] = 'Failed to Update Cache Expire Time.'
    end

    redirect_to resource_cache_cdn_path(resource_id) and return
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
