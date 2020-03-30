require 'securerandom'

class CdnsController < ApplicationController
  include HTTParty
  before_action :set_cdn, only: [:show, :update, :destroy]
  before_action :require_user, only: [:index, :register_account, :resource_cdn, :update_custom_domain]
  before_action :set_tab_name, only: [:resource_cdn, :update_resource, :add_custom_domain, :update_advanced_setting,
                                      :update_custom_domain, :purge_cache, :update_cache_expiry, :delete_resource]

  before_action :global_set_row_page, only: [:index]

  # before_action :require_user, only: [:index, :register_account, :resource_cdn, :update_custom_domain]

  # filter_access_to :all
  # filter_access_to :index, :resource_cdn, require: :read
  # filter_access_to :create, :register_account, :add_custom_domain, require: :new
  # filter_access_to :update_resource, :update_advanced_setting, :update_cache_expiry, require: :update
  # filter_access_to :update_resources, :purge_cache, :delete_resource, require: :delete
  # filter_access_to :update_custom_domain, require: [:new, :update, :delete]

  DUPLICATE_CUSTOM_DOMAIN = "This custom domain is already in use."

  # # GET /cdns
  # # GET /cdns.json
  def index
    @results = {}

    if current_user.ssl_account
      @response = current_user.is_system_admins? ?
                      HTTParty.get('https://reseller.cdnify.com/api/v1/resources/all-reseller-resources',
                                   basic_auth: {username: current_user_api_key, password: 'x'}) :
                      HTTParty.get('https://reseller.cdnify.com/api/v1/resources',
                                   basic_auth: {username: current_user_api_key, password: 'x'})

      if @response && @response.code == 200
        resources = @response.parsed_response['resources'].sort_by {|resource| resource['created_at']}.reverse
        @results[:resources] = resources.paginate(@p)
      else
        @results[:resources] = [].paginate(@p)
      end
    end

    respond_to do |format|
      format.html { render :action => :index }
      format.xml { render :xml => @results }
    end
  end

  def register_account
    returnObj = {}
    if current_user.ssl_account
      reseller_api_key = Rails.application.secrets.cdnify_reseller_api_key

      email_addr = current_user.ssl_account.acct_number + '@ssl.com'
      email_addr = 'sandbox-' + email_addr if is_sandbox?
      password = SecureRandom.hex(32)

      @response = HTTParty.post('https://reseller.cdnify.com/users',
                                {basic_auth: {username: reseller_api_key, password: 'x'}, body: {email: email_addr, password: password}})

      if @response &&
          @response.parsed_response &&
          @response.parsed_response['users'] &&
          @response.parsed_response['users'].length > 0
        returnObj['api_key'] = @response.parsed_response['users'][0]['api_key']
      elsif @response && @response.parsed_response && @response.parsed_response['error']
        returnObj['error'] = @response.parsed_response['error']
      else
        returnObj['error'] = 'Failed to Register Account.'
      end
    else
      returnObj['error'] = 'Failed to Register Account Because Current User have not SSL Account.'
    end

    render :json => returnObj
  end

  def delete_resources
    resources = params['deleted_resources']

    resources.each do |resource|
      resource = resource.split('|')
      resource_id, resource_name, api_key = resource[0], resource[1], resource[2]
      @response = Cdnify.destroy_cdn_resources(resource_id, api_key)

      if @response.code == 204
        flash[:notice] = 'Resources Successfully Deleted.'
      else
        @response.parsed_response['errors'].each do |error|
          flash[:error] = "#{resource_name}: #{error['code']}: #{error['message']}"
        end
      end
    end

    redirect_to cdns_path(ssl_slug: @ssl_slug)
  end

  def resource_cdn
    @results = {}
    @results[:bandwidth] = 0
    @results[:hits] = 0
    @results[:locations] = nil

    if current_user.ssl_account
      resource_id = params['id']
      @results[:active_tab] = @tab_overview
      @results[:active_tab] = session[:selected_tab] if session[:selected_tab]
      session.delete(:selected_tab)

      # Getting user api key for resource.
      if current_user.is_system_admins?
        if session[:user_api_key]
          api_key = current_user_api_key(session[:user_api_key])
          session.delete(:user_api_key)
        else
          admin_user_api_key = Rails.application.secrets.cdnify_admin_user_api_key
          @response = HTTParty.get('https://reseller.cdnify.com/api/v1/resources/all-reseller-resources',
                                   basic_auth: {username: admin_user_api_key, password: 'x'})

          if @response && @response.code == 200
            @response.parsed_response['resources'].each do |resource|
              if resource['id'] == resource_id
                api_key = current_user_api_key(resource['user_api_key'])
                break
              end
            end
          end
        end
      else
        api_key = current_user_api_key
        session.delete(:user_api_key) if session[:user_api_key]
      end

      if api_key
        # Overview Data
        @response = HTTParty.get('https://reseller.cdnify.com/api/v1/stats/' + resource_id + '/bandwidth',
                                 basic_auth: {username: api_key, password: 'x'})

        if @response && @response.parsed_response
          @results[:bandwidth] = @response.parsed_response['bandwidth_usage'] &&
              @response.parsed_response['bandwidth_usage'].length > 0 ?
                                     @response.parsed_response['bandwidth_usage'][0] : 0
          @results[:hits] = @response.parsed_response['hit_usage'] &&
              @response.parsed_response['hit_usage'].length > 0 ?
                                @response.parsed_response['hit_usage'][0] : 0
          @results[:locations] = @response.parsed_response['pop_usage'] &&
              @response.parsed_response['pop_usage'].length > 0 ?
                                     @response.parsed_response['pop_usage'][0] : nil
        end

        # Settings Data
        @response = HTTParty.get('https://reseller.cdnify.com/api/v1/resources/' + resource_id,
                                 basic_auth: {username: api_key, password: 'x'})
        @results[:resource] = @response.parsed_response['resources'][0] if @response && @response.parsed_response

        # Cache Data
        @results[:expire_time] = @response.parsed_response['resources'][0]['advanced_settings']['cache_expire_time'] if @response && @response.parsed_response

        @response = HTTParty.get('https://reseller.cdnify.com/api/v1/resources/' + resource_id + '/cache',
                                 basic_auth: {username: api_key, password: 'x'})
        @results[:files] = @response.parsed_response['files'] if @response && @response.parsed_response && @response.parsed_response['files']
      else
        flash[:error] = 'Unable to load selected resource.'
      end
    end

    respond_to do |format|
      format.html { render :action => "resource_cdn" }
      format.xml { render :xml => @results }
    end
  end

  def update_resource
    api_key = cdn_update_params[:api_key]
    resource_id = cdn_update_params[:id]
    @response = Cdnify.update_cdn_resource(cdn_update_params)

    if @response.code == 200
      flash[:notice] = 'Successfully Updated General Settings.'
    else
      @response.parsed_response['errors'].each do |error|
        flash[:error] = "#{error['code']}" + ': ' + "#{error['message']}"
      end
    end

    session[:selected_tab] = @tab_setting
    session[:user_api_key] = api_key

    redirect_to resource_cdn_cdn_path(@ssl_slug, resource_id)
  end

  def add_custom_domain
    resource_id = params[:id]
    api_key = params[:api_key]
    custom_domain = params[:custom_domain]

    @response = HTTParty.post('https://reseller.cdnify.com/api/v1/resources/' + resource_id + '/custom_domains',
                              {basic_auth: {username: api_key, password: 'x'}, body: {hostname: custom_domain}})

    # certificate_value = params['certificate_value']
    # private_key = params['private_key']
    # @response = HTTParty.post('https://reseller.cdnify.com/api/v1/resources/' + resource_id + '/custom_domains',
    #                           {basic_auth: {username: api_key, password: 'x'},
    #                            body: {hostname: custom_domain, certificates: {certificate: certificate_value, privateKey: private_key}}})

    if @response && @response.parsed_response
      if @response.parsed_response['errors']
        @response.parsed_response['errors'].each do |error|
          flash[:error] = '' unless flash[:error]
          flash[:error].concat("<br />") unless flash[:error] == ''
          flash[:error].concat(error['code'].to_s + ': ' + error['message'])
        end
      elsif @response.parsed_response['message']
        if @response.parsed_response['id']
          flash[:notice] = @response.parsed_response['message']
        else
          flash[:error] = @response.parsed_response['message']
        end
      end
    else
      flash[:error] = 'Failed to Add a New Custom Domain.'
    end

    session[:selected_tab] = @tab_setting
    session[:user_api_key] = api_key

    redirect_to resource_cdn_cdn_path(@ssl_slug, resource_id) and return
  end

  def update_custom_domain
    resource_id = params[:id]
    api_key = params['api_key']
    host_name = params['host_name']
    custom_domain_ref = params['custom_domain_ref']
    action_type = params['action_type']
    generate_type = params['generate_type']

    if action_type == 'modify'
      body_params = {}
      ac = current_user.ssl_account.api_credential
      body_params['account_key'] = ac.account_key
      body_params['secret_key'] = ac.secret_key
      body_params['is_test'] = true if is_sandbox?
      body_params['ref'] = custom_domain_ref if custom_domain_ref != ''

      if generate_type == 'auto'
        @response = HTTParty.post('https://reseller.cdnify.com/api/v1/resources/' + resource_id + '/ssl_certificate/' + host_name,
                                  {basic_auth: {username: api_key, password: 'x'}, body: body_params})

        if @response
          if @response.code == 200 || @response.code == 201
            if Settings.cdn_ssl_notification_address.blank?
              flash[:notice] = "Successfully Modified."
            else
              flash[:notice] = "The processing SSL certificate request has been emailed."
              current_user.deliver_generate_install_ssl!(resource_id, host_name, Settings.cdn_ssl_notification_address)
            end
          else
            flash[:error] = @response.parsed_response['error']['message']
          end
        else
          flash[:error] = 'Failed to update custom domain'
        end
      else
        body_params['certificate'] = params['certificate_value']
        body_params['privateKey'] = params['private_key']

        @response = HTTParty.put('https://reseller.cdnify.com/api/v1/resources/' + resource_id + '/ssl_certificate/' + host_name,
                                  {basic_auth: {username: api_key, password: 'x'}, body: body_params})

        if @response
          if @response.code == 200 || @response.code == 201
            if Settings.cdn_ssl_notification_address.blank?
              flash[:notice] = "Successfully Modified."
            else
              flash[:notice] = "The processing SSL certificate request has been emailed."
              current_user.deliver_ssl_cert_private_key!(resource_id, host_name, @response.parsed_response['id'])
            end
          else
            flash[:error] = @response.parsed_response['message']
          end
        else
          flash[:error] = 'Failed to update custom domain'
        end
      end
    else
      @response = HTTParty.delete('https://reseller.cdnify.com/api/v1/resources/' + resource_id + '/custom_domains/' + host_name,
                                  basic_auth: {username: api_key, password: 'x'})

      if @response
        if @response.parsed_response
          if @response.parsed_response['errors']
            @response.parsed_response['errors'].each do |error|
              flash[:error] = '' unless flash[:error]
              flash[:error].concat("<br />") unless flash[:error] == ''
              flash[:error].concat(error['code'].to_s + ': ' + error['message'])
            end
          end
        else
          flash[:notice] = 'Successfully Deleted.'
        end
      else
        flash[:error] = 'Failed to delete custom domain'
      end
    end

    session[:selected_tab] = @tab_setting
    session[:user_api_key] = api_key

    redirect_to resource_cdn_cdn_path(@ssl_slug, resource_id) and return
  end

  def update_advanced_setting
    resource_id = params[:id]
    api_key = params[:api_key]

    @response = HTTParty.patch('https://reseller.cdnify.com/api/v1/resources/' + resource_id + '/settings',
                               {basic_auth: {username: api_key, password: 'x'}, body: {
                                   allow_robots: !params[:allow_robots].blank?,
                                   cache_query_string: !params[:cache_query_string].blank?,
                                   enable_cors: !params[:enable_cors].blank?,
                                   disable_gzip: !params[:disable_gzip].blank?,
                                   force_ssl: !params[:pull_https].blank?,
                                   pull_https: !params[:pull_https].blank?,
                                   link: !params[:link].blank?
                               }})

    if @response && @response.parsed_response
      if @response.parsed_response['resource']
        flash[:notice] = 'Successfully Updated Advanced Settings.'
      else
        @response.parsed_response['errors'].each do |error|
          flash[:error] = '' unless flash[:error]
          flash[:error].concat("<br />") unless flash[:error] == ''
          flash[:error].concat(error['code'].to_s + ': ' + error['message'])
        end
      end
    else
      flash[:error] = 'Failed to Update Advanced Settings.'
    end

    session[:selected_tab] = @tab_setting
    session[:user_api_key] = api_key

    redirect_to resource_cdn_cdn_path(@ssl_slug, resource_id) and return
  end

  def check_cname
    resource_name = params['resource_name'] + '.a.cdnify.io'
    custom_domain = params['custom_domain']

    exist = begin
      Timeout.timeout(Surl::TIMEOUT_DURATION) do
        txt = Resolv::DNS.open do |dns|
          records = dns.getresources(custom_domain, Resolv::DNS::Resource::IN::CNAME)
        end
        resource_name == txt.last.name.to_s
      end
    rescue Exception=>e
      false
    end

    render :json => exist
  end

  def delete_resource
    resource_id = params[:id]
    api_key = params[:api_key]

    @response = HTTParty.delete('https://reseller.cdnify.com/api/v1/resources/' + resource_id,
                                basic_auth: {username: api_key, password: 'x'})

    if @response
      if @response.parsed_response
        @response.parsed_response['errors'].each do |error|
          flash[:error] = '' unless flash[:error]
          flash[:error].concat("<br />") unless flash[:error] == ''
          flash[:error].concat(error['code'].to_s + ': ' + error['message'])
        end

        session[:selected_tab] = @tab_setting

        redirect_to resource_cdn_cdn_path(@ssl_slug, resource_id) and return
      else
        flash[:notice] = 'Successfully Deleted Resource.'
      end
    else
      flash[:error] = 'Failed to delete resource.'
    end

    redirect_to cdns_path(ssl_slug: @ssl_slug)
  end

  def purge_cache
    resource_id = params[:id]
    api_key = params[:api_key]
    files = params[:purge_files].split(',')
    is_purge_all = params[:purge_all]

    if is_purge_all == 'true'
      @response = HTTParty.delete('https://reseller.cdnify.com/api/v1/resources/' + resource_id + '/cache',
                                  basic_auth: {username: api_key, password: 'x'})
    else
      @response = HTTParty.delete('https://reseller.cdnify.com/api/v1/resources/' + resource_id + '/cache',
                                  {basic_auth: {username: api_key, password: 'x'}, body: {files: files}})
    end

    if @response
      if @response.parsed_response
        @response.parsed_response['errors'].each do |error|
          flash[:error] = '' unless flash[:error]
          flash[:error].concat("<br />") unless flash[:error] == ''
          flash[:error].concat(error['code'].to_s + ': ' + error['message'])
        end
      else
        flash[:notice] = 'Successfully Purged File(s).'
      end
    else
      flash[:error] = 'Failed to purge file(s).'
    end

    session[:selected_tab] = @tab_cache
    session[:user_api_key] = api_key

    redirect_to resource_cdn_cdn_path(@ssl_slug, resource_id) and return
  end

  def update_cache_expiry
    resource_id = params[:id]
    api_key = params[:api_key]

    @response = HTTParty.patch('https://reseller.cdnify.com/api/v1/resources/' + resource_id + '/settings',
                               {basic_auth: {username: api_key, password: 'x'}, body: {cache_expire_time: params[:expiry_hours]}})

    if @response && @response.parsed_response
      if @response.parsed_response['resource']
        flash[:notice] = 'Successfully Updated Cache Expire Time.'
      else
        @response.parsed_response['errors'].each do |error|
          flash[:error] = '' unless flash[:error]
          flash[:error].concat("<br />") unless flash[:error] == ''
          flash[:error].concat(error['code'].to_s + ': ' + error['message'])
        end
      end
    else
      flash[:error] = 'Failed to Update Cache Expire Time.'
    end

    session[:selected_tab] = @tab_cache
    session[:user_api_key] = api_key

    redirect_to resource_cdn_cdn_path(@ssl_slug, resource_id) and return
  end

  # GET /cdns/1
  # GET /cdns/1.json
  def show
    render json: @cdn
  end

  # POST /cdns
  # POST /cdns.json
  def create
    @response = Cdnify.create_cdn_resource(cdn_params)

    if @response.parsed_response["resources"]
      flash[:notice] = 'Successfully Created Resource.'
    else
      @response.parsed_response['errors'].each do |error|
        flash[:error] = "#{error['code']}" + ': ' + "#{error['message']}"
      end
    end

    redirect_to cdns_path(ssl_slug: @ssl_slug)
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
      @cdn = (current_user.is_system_admins? ? Cdn : current_user.ssl_account.cdns).find(params[:id])
    end

    def set_tab_name
      @tab_overview = 'overview'
      @tab_cache = 'caches'
      @tab_setting = 'settings'
    end

    def cdn_params
      params.permit(:api_key, :resource_origin, :resource_name)
    end

    def cdn_update_params
      params.permit(:api_key, :resource_origin, :resource_name, :id)
    end

    def current_user_api_key(key = nil)
      return @current_user_api_key if defined?(@current_user_api_key)

      if key
        @current_user_api_key = key
      else
        if current_user.is_system_admins?
          @current_user_api_key = Rails.application.secrets.cdnify_admin_user_api_key
        else
          email_addr = current_user.ssl_account.acct_number + '@ssl.com'
          email_addr = 'sandbox-' + email_addr if is_sandbox?
          reseller_api_key = Rails.application.secrets.cdnify_reseller_api_key

          @response = HTTParty.get('https://reseller.cdnify.com/users/' + email_addr + '?email=True',
                                   basic_auth: {username: reseller_api_key, password: 'x'})

          @current_user_api_key = @response && @response.code == 200 ? @response.parsed_response['users'][0]['api_key'] : nil
        end
      end
    end
  end
