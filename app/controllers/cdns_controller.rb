require 'securerandom'

class CdnsController < ApplicationController
  include HTTParty
  before_action :set_cdn, only: [:show, :update, :destroy]
  before_action :require_user, only: [:index, :register_account, :register_api_key, :resource_cdn, :update_custom_domain]
  before_action :set_tab_name, only: [:resource_cdn, :update_resource, :add_custom_domain, :update_advanced_setting,
                                      :update_custom_domain, :purge_cache, :update_cache_expiry, :delete_resource]

  DUPLICATE_CUSTOM_DOMAIN = "This custom domain is already in use."

  # # GET /cdns
  # # GET /cdns.json
  def index
    @results = {}
    # @results[:is_admin] = current_user.is_system_admins?

    if current_user.ssl_account
      cdn = Cdn.where(ssl_account_id: current_user.ssl_account.id).last

      if cdn
        @results[:api_key] = cdn.api_key

        @response = HTTParty.get('https://reseller.cdnify.com/api/v1/resources',
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
      reseller_api_key = Rails.application.secrets.cdnify_reseller_api_key

      email_addr = current_user.ssl_account.acct_number + '@ssl.com'
      email_addr = 'sandbox-' + email_addr if is_sandbox?
      password = SecureRandom.hex(32)

      @response = HTTParty.post('https://reseller.cdnify.com/users',
                                {basic_auth: {username: reseller_api_key, password: 'x'}, body: {email: email_addr, password: password}})

      if @response.parsed_response &&
          @response.parsed_response['users'] &&
          @response.parsed_response['users'].length > 0
        api_key = @response.parsed_response['users'][0]['api_key']

        cdn = Cdn.new
        cdn.api_key = api_key
        cdn.ssl_account_id = current_user.ssl_account.id
        cdn.save

        flash[:notice] = 'Successfully Registered Account.'
      elsif @response.parsed_response && @response.parsed_response['error']
        flash[:error] = @response.parsed_response['error']
      else
        flash[:error] = 'Failed to Register Account.'
      end
    else
      flash[:error] = 'Failed to Register Account Because Current User have not SSL Account.'
    end

    redirect_to cdns_path(ssl_slug: @ssl_slug)
  end

  # def register_api_key
  #   if current_user.ssl_account
  #     cdn = Cdn.where(ssl_account_id: current_user.ssl_account.id).last
  #     cdn.api_key = params[:api_key]
  #     cdn.save
  #
  #     flash[:notice] = 'Successfully Updated API Key.'
  #   else
  #     flash[:error] = 'Failed to Update API Key.'
  #   end
  #
  #   redirect_to cdns_path(ssl_slug: @ssl_slug)
  # end

  def update_resources
    resources = params['deleted_resources']
    is_deleted = true

    if resources
      resources.each do |resource_id|
        @response = HTTParty.delete('https://reseller.cdnify.com/api/v1/resources/' + resource_id,
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

    redirect_to cdns_path(ssl_slug: @ssl_slug)
  end

  def resource_cdn
    resource_id = params['id']
    @results = {}

    unless current_user.ssl_account.blank?
      cdn = Cdn.where(ssl_account_id: current_user.ssl_account.id).first

      if cdn
        @results[:active_tab] = @tab_overview
        @results[:active_tab] = session[:selected_tab] if session[:selected_tab]
        session.delete(:selected_tab)

        # Overview Data
        @results[:api_key] = cdn.api_key
        @response = HTTParty.get('https://reseller.cdnify.com/api/v1/stats/' + resource_id + '/bandwidth',
                                 basic_auth: {username: cdn.api_key, password: 'x'})

        if @response.parsed_response
          @results[:bandwidth] = @response.parsed_response['bandwidth_usage'] &&
              @response.parsed_response['bandwidth_usage'].length > 0 ?
                                     @response.parsed_response['bandwidth_usage'][0] : 0
          @results[:hits] = @response.parsed_response['hit_usage'] &&
              @response.parsed_response['hit_usage'].length > 0 ?
                                @response.parsed_response['hit_usage'][0] : 0
          @results[:locations] = @response.parsed_response['pop_usage'] &&
              @response.parsed_response['pop_usage'].length > 0 ?
                                     @response.parsed_response['pop_usage'][0] : nil
        else
          @results[:bandwidth] = 0
          @results[:hits] = 0
          @results[:locations] = nil
        end

        # Settings Data
        @response = HTTParty.get('https://reseller.cdnify.com/api/v1/resources/' + resource_id,
                                 basic_auth: {username: cdn.api_key, password: 'x'})
        @results[:resource] = @response.parsed_response['resources'][0] if @response.parsed_response

        # Cache Data
        @results[:expire_time] = @response.parsed_response['resources'][0]['advanced_settings']['cache_expire_time'] if @response.parsed_response

        @response = HTTParty.get('https://reseller.cdnify.com/api/v1/resources/' + resource_id + '/cache',
                                 basic_auth: {username: cdn.api_key, password: 'x'})
        @results[:files] = @response.parsed_response['files'] if @response.parsed_response && @response.parsed_response['files']
      end
    end

    respond_to do |format|
      format.html { render :action => "resource_cdn" }
      format.xml { render :xml => @results }
    end
  end

  def update_resource
    resource_id = params[:id]
    api_key = params[:api_key]
    resource_origin = params[:resource_origin]
    resource_name = params[:resource_name]

    @response = HTTParty.patch('https://reseller.cdnify.com/api/v1/resources/' + resource_id,
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

    session[:selected_tab] = @tab_setting

    redirect_to resource_cdn_cdn_path(@ssl_slug, resource_id) and return
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

    if @response.parsed_response
      if @response.parsed_response['errors']
        @response.parsed_response['errors'].each do |error|
          msg = error['code'].to_s + ': ' + error['message']
          flash[:error] = msg
        end
      elsif @response.parsed_response['message']
        if @response.parsed_response['id']
          cdn = Cdn.new
          cdn.api_key = api_key
          cdn.ssl_account_id = current_user.ssl_account.id
          cdn.custom_domain_name = custom_domain
          cdn.save

          flash[:notice] = @response.parsed_response['message']
        else
          flash[:error] = @response.parsed_response['message']
        end
      end
    else
      flash[:error] = 'Failed to Add a New Custom Domain.'
    end

    session[:selected_tab] = @tab_setting

    redirect_to resource_cdn_cdn_path(@ssl_slug, resource_id) and return
  end

  def update_custom_domain
    resource_id = params[:id]
    action_type = params['action_type']
    api_key = params['api_key']
    host_name = params['host_name']
    generate_type = params['generate_type']
    cdn = Cdn.where(custom_domain_name: host_name).first

    if action_type == 'modify'
      byebug
      body_params = {}
      ac = current_user.ssl_account.api_credential
      body_params['account_key'] = ac.account_key
      body_params['secret_key'] = ac.secret_key
      body_params['is_test'] = is_sandbox? ? 'Y' : 'N'
      body_params['ref'] = cdn.certificate_order_ref if cdn && cdn.certificate_order_ref

      if generate_type == 'auto'
        @response = HTTParty.post('https://reseller.cdnify.com/api/v1/resources/' + resource_id + '/ssl_certificate/' + host_name,
                                  {basic_auth: {username: api_key, password: 'x'},
                                   body: body_params})

        # @response = HTTParty.post('https://reseller.cdnify.com/api/v1/resources/fa4b779/ssl_certificate/testcdn.ee.auth.gr',
        #                           {basic_auth: {username: '38b4ffb5b930cb33a4da982359a60298c6a7b00f3d995eff93', password: 'x'},
        #                            body: body_params})

        if @response.code == 200 || @response.code == 201
          cdn.update_attribute(:certificate_order_ref, @response['message']['ref']) if cdn && cdn.certificate_order_ref != @response['message']['ref']

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
        body_params['certificate'] = params['certificate_value']
        body_params['privateKey'] = params['private_key']

        @response = HTTParty.put('https://reseller.cdnify.com/api/v1/resources/' + resource_id + '/ssl_certificate/' + host_name,
                                  {basic_auth: {username: api_key, password: 'x'},
                                   body: body_params})

        # @response = HTTParty.put('https://reseller.cdnify.com/api/v1/resources/fa4b779/ssl_certificate/testcdn.ee.auth.gr',
        #                           {basic_auth: {username: '38b4ffb5b930cb33a4da982359a60298c6a7b00f3d995eff93', password: 'x'},
        #                            body: body_params})

        if @response.code == 200 || @response.code == 201
          cdn.update_attribute(:certificate_order_ref, @response['message']['ref']) if cdn && cdn.certificate_order_ref != @response['message']['ref']

          if Settings.cdn_ssl_notification_address.blank?
            flash[:notice] = "Successfully Modified."
          else
            flash[:notice] = "The processing SSL certificate request has been emailed."
            current_user.deliver_ssl_cert_private_key!(resource_id, host_name, @response.parsed_response['id'])
          end
        else
          flash[:error] = @response.parsed_response['message']
        end
      end

      # @response = update_cert_private_key(resource_id, host_name, api_key, certificate_value, private_key)
      #
      # if @response.parsed_response && @response.parsed_response['errors']
      #   @response.parsed_response['errors'].each do |error|
      #     msg = error['code'].to_s + ': ' + error['message']
      #     flash[:error] = msg
      #   end
      # elsif @response.parsed_response && @response.parsed_response['message']
      #   if  @response.parsed_response['id']
      #     flash[:notice] = @response.parsed_response['message']
      #
      #     # TODO: Email Sent
      #     # current_user.deliver_ssl_cert_private_key!(resource_id, host_name, @response.parsed_response['id'])
      #   else
      #     if @response.parsed_response['message'] == DUPLICATE_CUSTOM_DOMAIN
      #       @response = delete_custom_domain(resource_id, host_name, api_key)
      #
      #       if @response.parsed_response
      #         if @response.parsed_response['errors']
      #           @response.parsed_response['errors'].each do |error|
      #             msg = error['code'].to_s + ': ' + error['message']
      #             flash[:error] = msg
      #           end
      #         end
      #       else
      #         @response = update_cert_private_key(resource_id, host_name, api_key, certificate_value, private_key)
      #
      #         if @response.parsed_response && @response.parsed_response['errors']
      #           @response.parsed_response['errors'].each do |error|
      #             msg = error['code'].to_s + ': ' + error['message']
      #             flash[:error] = msg
      #           end
      #         elsif @response.parsed_response && @response.parsed_response['message']
      #           if  @response.parsed_response['id']
      #             flash[:notice] = @response.parsed_response['message']
      #
      #             # TODO: Email Sent
      #             # current_user.deliver_ssl_cert_private_key!(resource_id, host_name, @response.parsed_response['id'])
      #           else
      #             flash[:error] = @response.parsed_response['message']
      #           end
      #         end
      #       end
      #     else
      #       flash[:error] = @response.parsed_response['message']
      #     end
      #   end
    # end
    else
      @response = HTTParty.delete('https://reseller.cdnify.com/api/v1/resources/' + resource_id + '/custom_domains/' + host_name,
                                  basic_auth: {username: api_key, password: 'x'})

      if @response.parsed_response
        if @response.parsed_response['errors']
          @response.parsed_response['errors'].each do |error|
            msg = error['code'].to_s + ': ' + error['message']
            flash[:error] = msg
          end
        end
      else
        cdn.destroy if cdn
        flash[:notice] = 'Successfully Deleted.'
      end
    end

    session[:selected_tab] = @tab_setting

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

    session[:selected_tab] = @tab_setting

    redirect_to resource_cdn_cdn_path(@ssl_slug, resource_id) and return
  end

  def delete_resource
    resource_id = params[:id]
    api_key = params[:api_key]

    @response = HTTParty.delete('https://reseller.cdnify.com/api/v1/resources/' + resource_id,
                                basic_auth: {username: api_key, password: 'x'})

    if @response.parsed_response
      @response.parsed_response['errors'].each do |error|
        msg = error['code'].to_s + ': ' + error['message']
        flash[:error] = msg
      end

      session[:selected_tab] = @tab_setting

      redirect_to resource_cdn_cdn_path(@ssl_slug, resource_id) and return
    else
      flash[:notice] = 'Successfully Deleted Resource.'
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

    if @response.parsed_response
      @response.parsed_response['errors'].each do |error|
        msg = error['code'].to_s + ': ' + error['message']
        flash[:error] = msg
      end
    else
      flash[:notice] = 'Successfully Purged File(s).'
    end

    session[:selected_tab] = @tab_cache

    redirect_to resource_cdn_cdn_path(@ssl_slug, resource_id) and return
  end

  def update_cache_expiry
    resource_id = params[:id]
    api_key = params[:api_key]

    @response = HTTParty.patch('https://reseller.cdnify.com/api/v1/resources/' + resource_id + '/settings',
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

    session[:selected_tab] = @tab_cache

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
    api_key = params[:api_key]
    resource_name = params[:resource_name]
    resource_origin = params[:resource_origin]

    @response = HTTParty.post('https://reseller.cdnify.com/api/v1/resources',
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
      @cdn = Cdn.find(params[:id])
    end

    def set_tab_name
      @tab_overview = 'overview'
      @tab_cache = 'caches'
      @tab_setting = 'settings'
    end

    def cdn_params
      params.require(:cdn).permit()
    end

    # def update_cert_private_key(resource_id, host_name, api_key, certificate_value, private_key)
    #   HTTParty.post('https://reseller.cdnify.com/api/v1/resources/' + resource_id + '/custom_domains',
    #                             {basic_auth: {username: api_key, password: 'x'},
    #                              body: {hostname: host_name, certificates: {certificate: certificate_value, privateKey: private_key}}})
    # end
    #
    # def delete_custom_domain(resource_id, host_name, api_key)
    #   HTTParty.delete('https://reseller.cdnify.com/api/v1/resources/' + resource_id + '/custom_domains/' + host_name,
    #                               basic_auth: {username: api_key, password: 'x'})
    # end
end
