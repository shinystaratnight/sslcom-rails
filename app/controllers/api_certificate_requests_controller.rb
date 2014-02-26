class ApiCertificateRequestsController < ApplicationController
  before_filter :set_test
  skip_filter :identify_visitor, :record_visit

  wrap_parameters ApiCertificateRequest, include:
      [*(ApiCertificateRequest::ACCESSORS+
          ApiCertificateRequest::RETRIEVE_ACCESSORS+
          ApiCertificateRequest::REPROCESS_ACCESSORS+
          ApiCertificateRequest::DCV_EMAILS_ACCESSORS).uniq]
  respond_to :xml, :json

  TEST_SUBDOMAIN = "sws-test"

  rescue_from MultiJson::DecodeError do |exception|
    render :text => exception.to_s, :status => 422
  end

  def create_v1_3
    @result = ApiCertificateCreate.new(params[:api_certificate_request])
    record_parameters
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
  rescue
    error(500, 500, "server error")
  end

  def reprocess_v1_3
    @result = ApiCertificateCreate.new(params[:api_certificate_request])
    record_parameters
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
    @result = ApiCertificateRetrieve.new(params[:api_certificate_request])
    record_parameters
    if @result.valid?
      template = "api_certificate_requests/success_retrieve_v1_3"
      @result.order_status = ApiCertificateRequest::ORDER_STATUS[2]
      @result.update_attribute :response, render_to_string(:template => template)
      render(:template => template) and return
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
    end
    render action: :create_v1_3
  end

  def dcv_emails_v1_3
    @result=ApiDcvEmails.new(params[:api_certificate_request])
    record_parameters
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

  def dcv_email_resend_v1_3
    @result=ApiDcvEmailResend.new(params[:api_certificate_request])
    record_parameters
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
    @result=ApiDcvEmails.new(params[:api_certificate_request])
    record_parameters
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
    @result.test = @test
    @result.request_url = request.url
    @result.parameters = params.to_json
  end

  def decode_error
    render :text => "JSON request could not be parsed", :status => 400
  end

end
