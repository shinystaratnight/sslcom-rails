class ApiCertificateRequestsController < ApplicationController
  include SiteSealsHelper
  before_filter :set_test, :record_parameters, except: [:scan,:analyze]
  skip_filter :identify_visitor, :record_visit, :verify_authenticity_token
  after_filter :notify_saved_result
  layout false

  # parameters listed here made available as attributes in @result
  wrap_parameters ApiCertificateRequest, include:
      [*(ApiCertificateRequest::ACCESSORS+
          ApiCertificateRequest::CREATE_ACCESSORS_1_4+
          ApiCertificateRequest::RETRIEVE_ACCESSORS+
          ApiCertificateRequest::REPROCESS_ACCESSORS+
          ApiCertificateRequest::REVOKE_ACCESSORS+
          ApiCertificateRequest::DCV_EMAILS_ACCESSORS).uniq]
  respond_to :xml, :json

  TEST_SUBDOMAIN = "sws-test"
  ORDERS_DOMAIN = "https://#{Settings.community_domain}"
  SANDBOX_DOMAIN = "https://sandbox.ssl.com"
  SCAN_COMMAND=->(parameters, url){%x"echo QUIT | cipherscan/cipherscan #{parameters} #{url}"}
  ANALYZE_COMMAND=->(parameters, url){%x"echo QUIT | cipherscan/analyze.py #{parameters} #{url}"}

  rescue_from MultiJson::DecodeError do |exception|
    render :text => exception.to_s, :status => 422
  end

  def notify_saved_result
    @rendered=render_to_string(template: @template)
    unless @rendered.is_a?(String) && @rendered.include?('errors')
      @result.update_attribute :response, @rendered
      OrderNotifier.api_executed(@rendered, request.host_with_port).deliver if @rendered
    end
  end

  # set which parameters will be displayed via the api response
  def set_result_parameters(result, acr)
    ssl_slug               = acr.ssl_account.to_slug
    result.ref             = acr.ref
    result.order_status    = acr.status
    result.order_amount    = acr.order.amount.format
    domain = api_result_domain(acr)
    result.certificate_url = domain+certificate_order_path(ssl_slug, acr)
    result.receipt_url     = domain+order_path(ssl_slug, acr.order)
    result.smart_seal_url  = domain+certificate_order_site_seal_path(ssl_slug, acr.ref)
    result.validation_url  = domain+certificate_order_validation_path(ssl_slug, acr)
    result.registrant      = acr.certificate_content.registrant.to_api_query if (acr.certificate_content && acr.certificate_content.registrant)
  end

  def create_v1_4
    @template = 'api_certificate_requests/create_v1_4'
    if @result.csr_obj && !@result.csr_obj.valid?
      # we do this sloppy maneuver because the rabl template only reports errors
      @result = @result.csr_obj
    else
      if @result.valid? && @result.save
        if @acr = @result.create_certificate_order
          # successfully charged
          if @acr.is_a?(CertificateOrder) && @acr.errors.empty?      
            if @acr.certificate_content.csr && @result.debug
              ccr = @acr.certificate_content.csr.ca_certificate_requests.last
              @result.api_request=ccr.parameters
              @result.api_response=ccr.response
            end
            set_result_parameters(@result, @acr)
            render_200_status
          else
            @result = @acr #so that rabl can report errors
            render_400_status
          end
        end
      else
        InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
        render_400_status
      end
    end
  rescue => e
    render_500_error e
  end

  def revoke_v1_4
    @template = 'api_certificate_requests/revoke_v1_4'
    if @result.valid? && @result.save
      co = @result.find_certificate_order
      @acr = @result.find_signed_certificates(co)
      if @acr.is_a?(Array) && @result.errors.empty?
        if @result.serials.blank? #revoke the entire order
          co.revoke(@result.reason)
        else #revoke specific certs
          @acr.each do |signed_certificate|
            SystemAudit.create(owner: @result.api_credential, target: signed_certificate,
                               notes: "api revocation from ip address #{request.remote_ip}", action: "revoked")
            if signed_certificate.ca == "comodo"
              signed_certificate.revoke! @result.reason
            end
          end
        end
        @result.status = "revoked"
        render_200_status
      else
        render_400_status
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
      render_400_status
    end
  rescue => e
    render_500_error e
  end

  def update_v1_4
    @template = "api_certificate_requests/update_v1_4"
    if @result.csr_obj && !@result.csr_obj.valid?
      # we do this sloppy maneuver because the rabl template only reports errors
      @result = @result.csr_obj
    else
      if @result.save #save the api request
        if @acr = @result.update_certificate_order
          # successfully charged
          if @acr.is_a?(CertificateOrder) && @acr.errors.empty?
            if @acr.certificate_content.csr && @result.debug=="true"
              ccr = @acr.certificate_content.csr.ca_certificate_requests.first
              @result.api_request=ccr.parameters
              @result.api_response=ccr.response
            end
            # @result.error_code=ccr.response_error_code
            # @result.error_message=ccr.response_error_message
            # @result.eta=ccr.response_certificate_eta
            # @result.order_status = ccr.response_certificate_status
            set_result_parameters(@result, @acr)
            @result.debug=(@result.parameters_to_hash["debug"]=="true") # && @acr.admin_submitted = true
            render_200_status
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
    @template = "api_certificate_requests/success_retrieve_v1_3"
    if @result.save
      if @certificate_order.is_a?(CertificateOrder)
        @certificate_order.api_validate(@result)
        @result.order_status = @certificate_order.status
        @result.update_attribute :response, render_to_string(:template => @template)
        render(:template => @template) and return
      else
        InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
      end
    end
    render action: :create_v1_3
  end

  def show_v1_4
    @template = "api_certificate_requests/show_v1_4"
    if @result.save
      @acr = @result.find_certificate_order
      if @acr.is_a?(CertificateOrder) && @acr.errors.empty?
        @result.order_date = @acr.created_at
        @result.order_status = @acr.status
        @result.registrant = @acr.certificate_content.registrant.to_api_query if (@acr.certificate_content && @acr.certificate_content.registrant)
        @result.validations = @result.validations_from_comodo(@acr) #'validations' kept executing twice so it was renamed to 'validations_from_comodo'
        @result.description = @acr.description
        @result.product = @acr.certificate.api_product_code
        @result.subscriber_agreement = @acr.certificate.subscriber_agreement_content if @result.show_subscriber_agreement=~/[Yy]/
        if @acr.certificate.is_ucc?
          @result.domains_qty_purchased = @acr.purchased_domains('all').to_s
          @result.wildcard_qty_purchased = @acr.purchased_domains('wildcard').to_s
        else
          @result.domains_qty_purchased = "1"
          @result.wildcard_qty_purchased = @acr.certificate.is_wildcard? ? "1" : "0"
        end
        if (@acr.signed_certificate && @result.query_type!="order_status_only")
          @result.certificates =
              @acr.signed_certificate.to_format(response_type: @result.response_type, #assume comodo issued cert
                  response_encoding: @result.response_encoding) || @acr.signed_certificate.to_nginx
          @result.common_name = @acr.signed_certificate.common_name
          @result.subject_alternative_names = @acr.signed_certificate.subject_alternative_names
          @result.effective_date = @acr.signed_certificate.effective_date
          @result.expiration_date = @acr.signed_certificate.expiration_date
          @result.algorithm = @acr.signed_certificate.is_SHA2? ? "SHA256" : "SHA1"
          @result.site_seal_code = ERB::Util.json_escape(render_to_string(partial: 'site_seals/site_seal_code.html.haml',:locals=>{:co=>@acr},
                                                    layout: false))
        end
        render(:template => @template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
    end
  rescue => e
    logger.error e.message
    e.backtrace.each { |line| logger.error line }
    error(500, 500, "server error")
  end

  def api_parameters_v1_4
    if @result.save
      @acr = @result.find_certificate_order
      if @acr.is_a?(CertificateOrder) && @acr.errors.empty?
        api_domain = "https://" + (@acr.is_test ? Settings.test_api_domain : Settings.api_domain)
        @template = "api_certificate_requests/api_parameters_v1_4"
        @result.parameters = @acr.to_api_string(action: @result.api_call, domain_override: api_domain, caller: "api")
        render(:template => @template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
    end
  rescue => e
    logger.error e.message
    e.backtrace.each { |line| logger.error line }
    error(500, 500, "server error")
  end

  def scan
    @result=->(parameters, url) do
      timeout(60) do
        SCAN_COMMAND.call parameters, url
      end
    end
    respond_to do |format|
      format.html {render inline: @result.call("--curves", params[:url])}
      format.js {render json: @result.call("--curves -j", params[:url])}
      format.json {render json: @result.call("--curves -j", params[:url])}
    end
  end

  def analyze
    @result=->(parameters, url) do
      timeout(60) do
        ANALYZE_COMMAND.call parameters, url
      end
    end
    respond_to do |format|
      format.html {render inline: @result.call("-t", params[:url])}
      format.js {render json: @result.call("-j -t", params[:url])}
      format.json {render json: @result.call("-j -t", params[:url])}
    end
  end

  def index_v1_4
    @template = "api_certificate_requests/index_v1_4"
    @result.end = DateTime.now if @result.end.blank?
    if @result.save
      @acrs = @result.find_certificate_orders(params[:search])
      if @acrs.is_a?(ActiveRecord::Relation)# && @acrs.errors.empty?
        @results=[]
        @acrs.each do |acr|
          result = ApiCertificateRetrieve.new(ref: acr.ref)
          result.order_date = acr.created_at
          result.order_status = acr.status
          result.domains = acr.all_domains
          result.registrant = acr.certificate_content.registrant.to_api_query if (acr.certificate_content && acr.certificate_content.registrant)
          result.validations = result.validations_from_comodo(acr) #'validations' kept executing twice so it was renamed to 'validations_from_comodo'
          result.description = acr.description
          if acr.certificate.is_ucc?
            result.domains_qty_purchased = acr.purchased_domains('all').to_s
            result.wildcard_qty_purchased = acr.purchased_domains('wildcard').to_s
          else
            result.domains_qty_purchased = "1"
            result.wildcard_qty_purchased = acr.certificate.is_wildcard? ? "1" : "0"
          end
          if (acr.signed_certificate && result.query_type!="order_status_only")
            result.certificates =
                acr.signed_certificate.to_format(response_type: @result.response_type, #assume comodo issued cert
                    response_encoding: @result.response_encoding) || acr.signed_certificate.to_nginx
            result.common_name = acr.signed_certificate.common_name
            result.subject_alternative_names = acr.signed_certificate.subject_alternative_names
            result.effective_date = acr.signed_certificate.effective_date
            result.expiration_date = acr.signed_certificate.expiration_date
            result.algorithm = acr.signed_certificate.is_SHA2? ? "SHA256" : "SHA1"
            result.site_seal_code = ERB::Util.json_escape(render_to_string(partial: 'site_seals/site_seal_code.html.haml',:locals=>{:co=>acr},
                                                      layout: false))
          end
          @results<<result
        end
        render(:template => @template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
    end
  rescue => e
    logger.error e.message
    e.backtrace.each { |line| logger.error line }
    error(500, 500, "server error")
  end

  def reprocess_v1_3
    @template = "api_certificate_requests/success_create_v1_3"
    if @result.csr_obj && !@result.csr_obj.valid?
      # we do this sloppy maneuver because the rabl @template only reports errors
      @result = @result.csr_obj
    else
      if @result.save
        if @acr = @result.create_certificate_order
          # successfully charged
          if @acr.errors.empty?
            @result.ref = @acr.ref
            @result.order_status = "pending validation"
            @result.order_amount = @acr.order.amount.format
            @result.certificate_url = url_for(@acr)
            @result.receipt_url = url_for(@acr.order)
            @result.smart_seal_url = certificate_order_site_seal_url(certificate_order_id: @acr.ref)
            @result.validation_url = certificate_order_validation_url(certificate_order_id: @acr.ref)
            @result.update_attribute :response, render_to_string(:template => @template)
            render(:template => @template)
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
      @template = "api_certificate_requests/success_retrieve_v1_3"
      @result.order_status = @certificate_order.status
      @result.update_attribute :response, render_to_string(:template => @template)
      render(:template => @template) and return
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
        @template = "api_certificate_requests/dcv_emails_v1_3"
        render(:template => @template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
    end
  end

  def dcv_methods_v1_4
    @template = "api_certificate_requests/dcv_methods_v1_4"
    if @result.save  #save the api request
      @acr = @result.find_certificate_order
      if @acr.is_a?(CertificateOrder) && @acr.errors.empty?
      end
      @result.dcv_methods={}
      if @acr.all_domains
        @result.instructions = ApiDcvMethods::INSTRUCTIONS
        unless @acr.csr.blank?
          @result.md5_hash = @acr.csr.md5_hash
          @result.sha2_hash = @acr.csr.sha2_hash
          @result.dns_sha2_hash = @acr.csr.dns_sha2_hash
        end
        @acr.all_domains.each do |domain|
          @result.dcv_methods.merge! domain=>{}
          @result.dcv_methods[domain].merge! "email_addresses"=>ComodoApi.domain_control_email_choices(domain).email_address_choices
          unless @acr.csr.blank?
            @result.dcv_methods[domain].merge! "http_csr_hash"=>
                                                   {"http"=>"#{@acr.csr.dcv_url(domain)}",
                                                    "allow_https"=>"true",
                                                    "contents"=>"#{@result.sha2_hash}\ncomodoca.com#{"\n#{@acr.csr.unique_value}" unless @acr.csr.unique_value.blank?}"}
            @result.dcv_methods[domain].merge! "cname_csr_hash"=>{"cname"=>"#{@result.md5_hash}.#{domain}. CNAME #{@result.dns_sha2_hash}.comodoca.com.","name"=>"#{@result.md5_hash}.#{domain}","value"=>"#{@result.dns_sha2_hash}.comodoca.com."}
          end
        end
      end
      unless @result.dcv_methods.blank?
        render(:template => @template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
    end
  rescue => e
    logger.error e.message
    e.backtrace.each { |line| logger.error line }
    error(500, 500, "server error")
  end

  def dcv_methods_csr_hash_v1_4
    @template = "api_certificate_requests/dcv_methods_v1_4"
    if @result.save  #save the api request
      @acr = CertificateOrder.new
      @acr.certificate_contents.build.build_csr(body: @result.csr)
      if @acr.csr.errors.empty?
        @result.dcv_methods={}
        if @acr.csr.common_name
          @result.instructions = ApiDcvMethods::INSTRUCTIONS
          unless @acr.csr.blank?
            @result.md5_hash = @acr.csr.md5_hash
            @result.sha2_hash = @acr.csr.sha2_hash
            @result.dns_md5_hash = @acr.csr.dns_md5_hash
            @result.dns_sha2_hash = @acr.csr.dns_sha2_hash
          end
          ([@acr.csr.common_name]+(@result.domains || [])).uniq.each do |domain|
            @result.dcv_methods.merge! domain=>{}
            @result.dcv_methods[domain].merge! "email_addresses"=>ComodoApi.domain_control_email_choices(domain).email_address_choices
            unless @acr.csr.blank?
              @result.dcv_methods[domain].merge! "http_csr_hash"=>
                 {"http"=>"#{@acr.csr.dcv_url(domain)}",
                  "allow_https"=>"true",
                  "contents"=>"#{@result.sha2_hash}\ncomodoca.com#{"\n#{@acr.csr.unique_value}" unless @acr.csr.unique_value.blank?}"}
              @result.dcv_methods[domain].merge! "cname_csr_hash"=>{"cname"=>"#{@result.dns_md5_hash}.#{domain}. CNAME #{@result.dns_sha2_hash}.comodoca.com.","name"=>"#{@result.dns_md5_hash}.#{domain}","value"=>"#{@result.dns_sha2_hash}.comodoca.com."}
            end
          end
        end
        unless @result.dcv_methods.blank?
          render(:template => @template) and return
        end
      else
        @result=@acr.csr  #so that rabl can report errors
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
    end
    render action: :dcv_methods_v1_4
  rescue => e
    logger.error e.message
    e.backtrace.each { |line| logger.error line }
    error(500, 500, "server error")
  end

  def dcv_email_resend_v1_3
    if @result.save
      @result.sent_at=Time.now
      unless @result.email_addresses.blank?
        @template = "api_certificate_requests/success_dcv_email_resend_v1_3"
        render(:template => @template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
    end
    render action: :create_v1_3
  end

  def dcv_revoke_v1_3
    @template = "api_certificate_requests/success_dcv_emails_v1_3"
    if @result.save
      @result.email_addresses=ComodoApi.domain_control_email_choices(@result.domain_name).email_address_choices
      unless @result.email_addresses.blank?
        render(:template => @template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
    end
    render action: :create_v1_3
  end

  private

  def set_test
    @test = request.subdomain==TEST_SUBDOMAIN || %w{development test}.include?(Rails.env)
  end

  def record_parameters
    klass = case params[:action]
              when "create_v1_3"
                ApiCertificateCreate
              when "create_v1_4", "update_v1_4"
                ApiCertificateCreate_v1_4
              when "reprocess_v1_3"
                ApiCertificateCreate
              when /revoke/
                ApiCertificateRevoke
              when "retrieve_v1_3", "show_v1_4", "index_v1_4"
                ApiCertificateRetrieve
              when "api_parameters_v1_4"
                ApiParameters
              when "quote"
                ApiCertificateQuote
              when "dcv_email_resend_v1_3"
                ApiDcvEmailResend
              when "dcv_emails_v1_3", "dcv_revoke_v1_3"
                ApiDcvEmails
              when "dcv_methods_v1_4", "dcv_revoke_v1_3", "dcv_methods_csr_hash_v1_4"
                ApiDcvMethods
            end
    @result=klass.new(_wrap_parameters(params)['api_certificate_request'] || params[:api_certificate_request])
    @result.debug ||= params[:debug] if params[:debug]
    @result.send_to_ca ||= params[:send_to_ca] if params[:send_to_ca]
    @result.action ||= params[:action]
    @result.ref ||= params[:ref] if params[:ref]
    @result.options ||= params[:options] if params[:options]
    @result.test = @test
    @result.request_url = request.url
    @result.parameters = params.to_json
    @result.raw_request = request.raw_post
    @result.request_method = request.request_method
  end

  def find_certificate_order
    @certificate_order=@result.find_certificate_order
  end

  def decode_error
    render :text => "JSON request could not be parsed", :status => 400
  end
  
  def render_200_status
    render template: @template, status: 200
  end
  
  def render_400_status
    render template: @template, status: 400
  end
  
  def render_500_error(e)
    logger.error e.message
    e.backtrace.each { |line| logger.error line }
    error(500, 500, 'server error')
  end

  def api_result_domain(certificate_order=nil)
    unless certificate_order.blank?
      if Rails.env=~/production/i
        "https://" + (certificate_order.is_test ? Settings.sandbox_domain : Settings.portal_domain)
      else
        "https://" + (certificate_order.is_test ? Settings.dev_sandbox_domain : Settings.dev_portal_domain) +":3000"
      end
    else
      if is_sandbox?
        Rails.env=~/production/i ? "https://#{Settings.sandbox_domain}" : "https://#{Settings.dev_sandbox_domain}:3000"
      else
        Rails.env=~/production/i ? "https://#{Settings.portal_domain}" : "https://#{Settings.dev_portal_domain}:3000"
      end
    end
  end
end
