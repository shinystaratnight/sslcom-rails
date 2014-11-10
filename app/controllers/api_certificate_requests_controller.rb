class ApiCertificateRequestsController < ApplicationController
  before_filter :set_test, :record_parameters
  skip_filter :identify_visitor, :record_visit, :verify_authenticity_token

  wrap_parameters ApiCertificateRequest, include:
      [*(ApiCertificateRequest::ACCESSORS+
          ApiCertificateRequest::CREATE_ACCESSORS_1_4+
          ApiCertificateRequest::RETRIEVE_ACCESSORS+
          ApiCertificateRequest::REPROCESS_ACCESSORS+
          ApiCertificateRequest::DCV_EMAILS_ACCESSORS).uniq]
  respond_to :xml, :json

  TEST_SUBDOMAIN = "sws-test"

  rescue_from MultiJson::DecodeError do |exception|
    render :text => exception.to_s, :status => 422
  end

  def create_v1_3
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
            @result.smart_seal_url = certificate_order_site_seal_url(@acr)
            @result.validation_url = certificate_order_validation_url(@acr)
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
  rescue => e
    logger.error e.message
    e.backtrace.each { |line| logger.error line }
    error(500, 500, "server error")
  end

  def create_v1_4
    if @result.csr_obj && !@result.csr_obj.valid?
      # we do this sloppy maneuver because the rabl template only reports errors
      @result = @result.csr_obj
    else
      if @result.save
        if @acr = @result.create_certificate_order
          # successfully charged
          if @acr.is_a?(CertificateOrder) && @acr.errors.empty?
            template = "api_certificate_requests/success_create_v1_4"
            ccr = @acr.certificate_content.csr.ca_certificate_requests.last
            @result.api_request=ccr.parameters
            @result.api_response=ccr.response
            @result.ref = @acr.ref
            @result.order_status = @acr.status
            @result.order_amount = @acr.order.amount.format
            @result.certificate_url = url_for(@acr)
            @result.receipt_url = url_for(@acr.order)
            @result.smart_seal_url = certificate_order_site_seal_url(@acr)
            @result.validation_url = certificate_order_validation_url(@acr)
            @result.update_attribute :response, render_to_string(:template => template)
            @result.debug=(JSON.parse(@result.parameters)["debug"]=="true") # && @acr.admin_submitted = true
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

  def update_v1_4
    if @result.csr_obj && !@result.csr_obj.valid?
      # we do this sloppy maneuver because the rabl template only reports errors
      @result = @result.csr_obj
    else
      if @result.save
        if @acr = @result.update_certificate_order
          # successfully charged
          if @acr.is_a?(CertificateOrder) && @acr.errors.empty?
            template = "api_certificate_requests/update_v1_4"
            ccr = @acr.certificate_content.csr.ca_certificate_requests.last
            @result.api_request=ccr.parameters
            @result.api_response=ccr.response
            # @result.error_code=ccr.response_error_code
            # @result.error_message=ccr.response_error_message
            # @result.eta=ccr.response_certificate_eta
            # @result.order_status = ccr.response_certificate_status
            @result.order_status = @acr.status
            @result.ref = @acr.ref
            @result.order_amount = @acr.order.amount.format
            @result.certificate_url = url_for(@acr)
            @result.receipt_url = url_for(@acr.order)
            @result.smart_seal_url = certificate_order_site_seal_url(@acr)
            @result.validation_url = certificate_order_validation_url(@acr)
            @result.update_attribute :response, render_to_string(:template => template)
            @result.debug=(JSON.parse(@result.parameters)["debug"]=="true") # && @acr.admin_submitted = true
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

  def show_v1_4
    if @result.save
      @acr = @result.find_certificate_order
      if @acr.is_a?(CertificateOrder) && @acr.errors.empty?
        template = "api_certificate_requests/show_v1_4"
        @result.order_status = @acr.status
        @result.certificates = @acr.signed_certificate.to_format(response_type: @result.response_type,
          response_encoding: @result.response_encoding) if (@acr.signed_certificate &&
          @result.query_type!="order_status_only")
        @result.update_attribute :response, render_to_string(:template => template)
        render(:template => template) and return
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
            @result.smart_seal_url = certificate_order_site_seal_url(@acr)
            @result.validation_url = certificate_order_validation_url(@acr)
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
      if @result.domain_name
        @result.email_addresses=ComodoApi.domain_control_email_choices(@result.domain_name).email_address_choices
      else
        @result.domain_names.each do |domain|
          @result.email_addresses.merge! domain=>ComodoApi.domain_control_email_choices(domain).email_address_choices
        end
      end
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
    @test = (current_subdomain==TEST_SUBDOMAIN) ? true : false
  end

  def record_parameters
    klass = case params[:action]
              when "create_v1_3"
                ApiCertificateCreate
              when "create_v1_4", "update_v1_4"
                ApiCertificateCreate_v1_4
              when "reprocess_v1_3"
                ApiCertificateCreate
              when "retrieve_v1_3", "show_v1_4"
                ApiCertificateRetrieve
              when "dcv_email_resend_v1_3"
                ApiDcvEmailResend
              when "dcv_emails_v1_3", "dcv_revoke_v1_3"
                ApiDcvEmails
            end
    @result=klass.new(params[:api_certificate_request])
    @result.debug = params[:debug] if params[:debug]
    @result.send_to_ca = params[:send_to_ca] if params[:send_to_ca]
    @result.action = params[:action]
    @result.ref = params[:ref] if params[:ref]
    @result.test = @test
    @result.request_url = request.url
    @result.parameters = params.to_json
  end

  def find_certificate_order
    @certificate_order=@result.find_certificate_order
  end

  def decode_error
    render :text => "JSON request could not be parsed", :status => 400
  end
end
