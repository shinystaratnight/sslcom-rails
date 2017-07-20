class ApiUserRequestsController < ApplicationController
  before_filter :set_test, :record_parameters
  # before_filter :find_user, :only => [:show_v1_4]
  skip_filter :identify_visitor, :record_visit, :verify_authenticity_token

  wrap_parameters ApiUserRequest, include:
      [*(ApiUserRequest::CREATE_ACCESSORS_1_4).uniq]
  respond_to :xml, :json

  TEST_SUBDOMAIN = "sws-test"
  SITE_DOMAIN = "https://#{Settings.community_domain}"

  rescue_from MultiJson::DecodeError do |exception|
    render :text => exception.to_s, :status => 422
  end

  def set_result_parameters(result, aur, template)
    result.login = aur.login
    result.email = aur.email
    result.account_number=aur.ssl_account.acct_number
    result.status = aur.status
    result.user_url = SITE_DOMAIN+user_path(aur)
    result.update_attribute :response, render_to_string(:template => template)
  end

  def create_v1_4
    if @result.save
      if @obj = @result.create_user
        # successfully charged
        if @obj.is_a?(User) && @obj.errors.empty?
          template = "api_user_requests/create_v1_4"
          set_result_parameters(@result, @obj, template)
          @result.account_key=@obj.ssl_account.api_credential.account_key
          @result.secret_key=@obj.ssl_account.api_credential.secret_key
          # @result.debug=(JSON.parse(@result.parameters)["debug"]=="true") # && @obj.admin_submitted = true
          render(:template => template)
        else
          @result = @obj #so that rabl can report errors
        end
      end
    else
      InvalidApiUserRequest.create parameters: params
    end
  rescue => e
    logger.error e.message
    e.backtrace.each { |line| logger.error line }
    error(500, 500, "server error")
  end

  def show_v1_4
    if @result.save
      if @obj = UserSession.create(params).user
        # successfully charged
        if @obj.is_a?(User) && @obj.errors.empty?
          template = "api_user_requests/show_v1_4"
          set_result_parameters(@result, @obj, template)
          @result.account_key=@obj.ssl_account.api_credential.account_key
          @result.secret_key=@obj.ssl_account.api_credential.secret_key
          @result.available_funds=Money.new(@obj.ssl_account.funded_account.cents).format
          # @result.debug=(JSON.parse(@result.parameters)["debug"]=="true") # && @obj.admin_submitted = true
          render(:template => template)
        else
          @result = @obj #so that rabl can report errors
        end
      else
        @result.errors[:login] << "#{@result.login} not found or incorrect password"
      end
    else
      InvalidApiUserRequest.create parameters: params
    end
  rescue => e
    logger.error e.message
    e.backtrace.each { |line| logger.error line }
    error(500, 500, "server error")
  end

  def update_v1_4
    if @result.csr_obj && !@result.csr_obj.valid?
      # we do this sloppy maneuver because the rabl template only reports errors
      @result = @result.csr_obj
    else
      if @result.save #save the api request
        if @acr = @result.update_certificate_order
          # successfully charged
          if @acr.is_a?(CertificateOrder) && @acr.errors.empty?
            template = "api_certificate_requests/update_v1_4"
            if @acr.certificate_content.csr && @result.debug=="true"
              ccr = @acr.certificate_content.csr.ca_certificate_requests.first
              @result.api_request=ccr.parameters
              @result.api_response=ccr.response
            end
            # @result.error_code=ccr.response_error_code
            # @result.error_message=ccr.response_error_message
            # @result.eta=ccr.response_certificate_eta
            # @result.order_status = ccr.response_certificate_status
            set_result_parameters(@result, @acr, template)
            @result.debug=(@result.parameters_to_hash["debug"]=="true") # && @acr.admin_submitted = true
            render(:template => template)
          else
            @result = @acr #so that rabl can report errors
          end
        end
      else
        InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
      end
    end
  rescue => e
    logger.error e.message
    e.backtrace.each { |line| logger.error line }
    error(500, 500, "server error")
  end

  def dcv_validate_v1_4
    if @result.save
      if @certificate_order.is_a?(CertificateOrder)
        @certificate_order.api_validate(@result)
        template = "api_certificate_requests/success_retrieve_v1_3"
        @result.order_status = @certificate_order.status
        @result.update_attribute :response, render_to_string(:template => template)
        render(:template => template) and return
      else
        InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
      end
    end
    render action: :create_v1_3
  end

  def reprocess_v1_3
    if @result.csr_obj && !@result.csr_obj.valid?
      # we do this sloppy maneuver because the rabl template only reports errors
      @result = @result.csr_obj
    else
      if @result.save
        if @acr = @result.create_certificate_order
          # successfully charged
          if @acr.errors.empty?
            template = "api_certificate_requests/success_create_v1_3"
            @result.ref = @acr.ref
            @result.order_status = "pending validation"
            @result.order_amount = @acr.order.amount.format
            @result.certificate_url = url_for(@acr)
            @result.receipt_url = url_for(@acr.order)
            @result.smart_seal_url = certificate_order_site_seal_url(certificate_order_id: @acr.ref)
            @result.validation_url = certificate_order_validation_url(certificate_order_id: @acr.ref)
            @result.update_attribute :response, render_to_string(:template => template)
            render(:template => template)
          else
            @result = @acr #so that rabl can report errors
          end
        end
      else
        InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
      end
    end
  end

  def retrieve_v1_3
    if @result.save && @certificate_order.is_a?(CertificateOrder)
      template = "api_certificate_requests/success_retrieve_v1_3"
      @result.order_status = @certificate_order.status
      @result.update_attribute :response, render_to_string(:template => template)
      render(:template => template) and return
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
    end
    render action: :create_v1_3
  end

  def dcv_emails_v1_3
    if @result.save
      @result.email_addresses={}
      @certificate_order=find_certificate_order
      @certificate_order.is_a?(CertificateOrder)
      if @result.domain
        @result.email_addresses=ComodoApi.domain_control_email_choices(@result.domain).email_address_choices
      else
        @result.domains.each do |domain|
          @result.email_addresses.merge! domain=>ComodoApi.domain_control_email_choices(domain).email_address_choices
        end
      end
      unless @result.email_addresses.blank?
        template = "api_certificate_requests/dcv_emails_v1_3"
        @result.update_attribute :response, render_to_string(:template => template)
        render(:template => template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
    end
  end

  def dcv_methods_v1_4
    if @result.save  #save the api request
      @acr = @result.find_certificate_order
      if @acr.is_a?(CertificateOrder) && @acr.errors.empty?
        template = "api_certificate_requests/dcv_methods_v1_4"
      end
      @result.dcv_methods={}
      if @acr.domains
        @result.instructions = ApiDcvMethods::INSTRUCTIONS
        unless @acr.csr.blank?
          @result.md5_hash = @acr.csr.md5_hash
          @result.sha2_hash = @acr.csr.sha2_hash
          @result.dns_sha2_hash = @acr.csr.dns_sha2_hash
        end
        @acr.domains.each do |domain|
          @result.dcv_methods.merge! domain=>{}
          @result.dcv_methods[domain].merge! "email_addresses"=>ComodoApi.domain_control_email_choices(domain).email_address_choices
          unless @acr.csr.blank?
            @result.dcv_methods[domain].merge! "http_csr_hash"=>
                                                   {"http"=>"http://#{domain}/#{@result.md5_hash}.txt",
                                                    "allow_https"=>"true",
                                                    "contents"=>"#{@result.sha2_hash}\ncomodoca.com#{"\n#{@acr.csr.unique_value}" unless @acr.csr.unique_value.blank?}"}
            @result.dcv_methods[domain].merge! "cname_csr_hash"=>{"cname"=>"#{@result.md5_hash}.#{domain}. CNAME #{@result.dns_sha2_hash}.comodoca.com.","name"=>"#{@result.md5_hash}.#{domain}","value"=>"#{@result.dns_sha2_hash}.comodoca.com."}
          end
        end
      end
      unless @result.dcv_methods.blank?
        @result.update_attribute :response, render_to_string(:template => template)
        render(:template => template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
    end
  end

  def dcv_email_resend_v1_3
    if @result.save
      @result.sent_at=Time.now
      unless @result.email_addresses.blank?
        template = "api_certificate_requests/success_dcv_email_resend_v1_3"
        @result.update_attribute :response, render_to_string(:template => template)
        render(:template => template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
    end
    render action: :create_v1_3
  end

  def dcv_revoke_v1_3
    if @result.save
      @result.email_addresses=ComodoApi.domain_control_email_choices(@result.domain_name).email_address_choices
      unless @result.email_addresses.blank?
        template = "api_certificate_requests/success_dcv_emails_v1_3"
        @result.update_attribute :response, render_to_string(:template => template)
        render(:template => template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
    end
    render action: :create_v1_3
  end

  private

  def set_test
    @test = (request.subdomain==TEST_SUBDOMAIN) ? true : false
  end

  def record_parameters
    klass = case params[:action]
              when "create_v1_4", "update_v1_4"
                ApiUserCreate_v1_4
              when "show_v1_4"
                ApiUserShow_v1_4
            end
    @result=klass.new(params[:api_certificate_request] || _wrap_parameters(params)['api_user_request'])
    @result.debug = params[:debug] if params[:debug]
    @result.action = params[:action]
    @result.options = params[:options] if params[:options]
    @result.test = @test
    @result.request_url = request.url
    @result.parameters = params.to_json
    @result.raw_request = request.raw_post
    @result.request_method = request.request_method
  end

  def decode_error
    render :text => "JSON request could not be parsed", :status => 400
  end
end
