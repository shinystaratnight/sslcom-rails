class Api::V1::ApiCertificateRequestsController < Api::V1::APIController
  include ActionController::Helpers
  helper SiteSealsHelper
  before_filter :set_test, :record_parameters, except: [:scan,:analyze, :download_v1_4]
  after_filter :notify_saved_result, except: [:create_v1_4, :download_v1_4]

  # parameters listed here made available as attributes in @result
  wrap_parameters ApiCertificateRequest, include: [*( 
    ApiCertificateRequest::ACCESSORS+
    ApiCertificateRequest::CREATE_ACCESSORS_1_4+
    ApiCertificateRequest::RETRIEVE_ACCESSORS+
    ApiCertificateRequest::DETAILED_ACCESSORS+
    ApiCertificateRequest::REPROCESS_ACCESSORS+
    ApiCertificateRequest::REVOKE_ACCESSORS+
    ApiCertificateRequest::DCV_EMAILS_ACCESSORS
  ).uniq]

  ORDERS_DOMAIN = "https://#{Settings.community_domain}"
  SANDBOX_DOMAIN = "https://sandbox.ssl.com"
  SCAN_COMMAND=->(parameters, url){%x"echo QUIT | cipherscan/cipherscan #{parameters} #{url}"}
  ANALYZE_COMMAND=->(parameters, url){%x"echo QUIT | cipherscan/analyze.py #{parameters} #{url}"}
  
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
    result.external_order_number = acr.ext_customer_ref
    result.certificate_url = domain+certificate_order_path(ssl_slug, acr)
    result.receipt_url     = domain+order_path(ssl_slug, acr.order)
    result.smart_seal_url  = domain+certificate_order_site_seal_path(ssl_slug, acr.ref)
    result.validation_url  = domain+certificate_order_validation_path(ssl_slug, acr)
    result.registrant      = acr.certificate_content.registrant.to_api_query if (acr.certificate_content && acr.certificate_content.registrant)
  end

  def create_v1_4
    @template = 'api_certificate_requests/create_v1_4'
    if @result.csr_obj && !@result.csr_obj.valid?
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
          else
            @result = @acr
          end
        end
      else
        InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
      end
    end
    render_200_status_noschema
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
            SystemAudit.create(
              owner:  @result.api_credential,
              target: signed_certificate,
              notes:  "api revocation from ip address #{request.remote_ip}",
              action: "revoked"
            )
            if signed_certificate.ca == "comodo"
              signed_certificate.revoke! @result.reason
            end
          end
        end
        @result.status = "revoked"
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
    end
    render_200_status
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
            end# @result.error_code=ccr.response_error_code
            # @result.error_message=ccr.response_error_message
            # @result.eta=ccr.response_certificate_eta
            # @result.order_status = ccr.response_certificate_status

            set_result_parameters(@result, @acr)
            @result.debug=(@result.parameters_to_hash["debug"]=="true") # && @acr.admin_submitted = true
          else
            @result = @acr #so that rabl can report errors
          end
        end
      else
        InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
      end
    end
    render_200_status
  rescue => e
    render_500_error e
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

  def detail_v1_4
    @template = "api_certificate_requests/detail_v1_4"

    if @result.save
      @acr = @result.find_certificate_order

      if @acr.is_a?(CertificateOrder) && @acr.errors.empty?
        @result.menu = {}

        @result.menu[:certificate_details_tab] = true
        @result.menu[:validation_status_tab] = true
        @result.menu[:smart_seal_tab] = true
        @result.menu[:transaction_receipt_tab] = true

        if @result.menu[:certificate_details_tab]
          @result.main = {}
          @result.main[:subject] = @acr.signed_certificate ? @acr.signed_certificate.common_name : nil
          @result.main[:order_status] = @acr.status
          @result.main[:order_date] = @acr.created_at
          @result.main[:expiry_date] = @acr.signed_certificate ?
                                           @acr.signed_certificate.expiration_date : nil

          @result.sub_main = {}
          @result.sub_main[:certificate_type] = certificate_type(@acr)
          @result.sub_main[:certificate_duration] = @acr.certificate_duration
          @result.sub_main[:validation_level] = @acr.certificate.description["validation_level"]

          if @acr.is_unused_credit? || @acr.certificate_content.csr.blank? || @acr.certificate_content.csr.signed_certificate.blank?
            @result.sub_main[:issued_date] = 'Pending'
          else
            @result.sub_main[:issued_date] = @acr.certificate_content.csr.signed_certificate.created_at.strftime("%b %d, %Y")
          end

          if @acr.is_unused_credit? || @acr.certificate_content.csr.blank?
            @result.sub_main[:requested_date] = 'N/A'
          else
            @result.sub_main[:requested_date] = @acr.certificate_content.csr.created_at.strftime("%b %d, %Y")
          end

          @result.certificate_content = {}
          @result.certificate_content[:csr_blank] = @acr.certificate_content.csr.blank?
          @result.certificate_content[:fields] = {}
          @result.certificate_content[:fields][:is_signed] = true
          if @acr.certificate_content.csr.signed_certificate.blank?
            csr = @acr.certificate_content.csr
            @result.certificate_content[:fields][:is_signed] = false
            @result.certificate_content[:fields][:organization] = csr.organization
            @result.certificate_content[:fields][:organization_unit] = csr.organization_unit
            @result.certificate_content[:fields][:locality] = csr.locality
            @result.certificate_content[:fields][:state] = csr.state
            @result.certificate_content[:fields][:country] = csr.country
          else
            sc = @acr.certificate_content.csr.signed_certificate
            @result.certificate_content[:fields][:algorithm] = sc.signature_algorithm
            @result.certificate_content[:fields][:decoded] = sc.decoded
          end

          @result.in_limit = (@acr.certificate_duration(:days).to_i > 1187) && (@acr.created_at > Date.parse('Apr 1 2015'))
          @result.registrant = @acr.certificate_content.registrant.to_api_query

          if @acr.certificate_content.issued? && !@acr.certificate_content.expired?
            csr, sc = @acr.csr, @acr.signed_certificate
            @result.download = {
                iis7: ["Microsoft IIS (*.p7b)", certificate_file("pkcs", @acr), SignedCertificate::IIS_INSTALL_LINK],
                cpanel: ["WHM/cpanel", certificate_file("whm_bundle", @acr), SignedCertificate::CPANEL_INSTALL_LINK],
                apache: ["Apache", certificate_file("apache_bundle", @acr), SignedCertificate::APACHE_INSTALL_LINK],
                amazon: ["Amazon", certificate_file("amazon_bundle", @acr), SignedCertificate::AMAZON_INSTALL_LINK],
                nginx: ["Nginx", certificate_file("nginx", @acr), SignedCertificate::NGINX_INSTALL_LINK],
                v8_nodejs: ["V8+Node.js", certificate_file("nginx", @acr), SignedCertificate::V8_NODEJS_INSTALL_LINK],
                java: ["Java/Tomcat", certificate_file("other", @acr), SignedCertificate::JAVA_INSTALL_LINK],
                other: ["Other platforms", certificate_file("other", @acr), SignedCertificate::OTHER_INSTALL_LINK],
                bundle: ["CA bundle (intermediate certs)", certificate_file("ca_bundle", @acr), SignedCertificate::OTHER_INSTALL_LINK]
            }
          end

          unless (@acr.certificate_content.csr.blank? ||
              (!@acr.certificate_content.show_validation_view? && @acr.is_test?))
            if @acr.certificate_content.pending_validation?
              @result.domain_validation = true
            end
            unless @acr.certificate.is_dv?
              @result.validation_document = {}

              unless @acr.certificate_content.blank? ||
                  @acr.certificate_content.new? ||
                  @acr.certificate_content.csr_submitted? ||
                  @acr.certificate_content.info_provided? ||
                  @acr.expired?
                @result.validation_document[:links] = {}
                @result.validation_document[:links][:status] = true

                unless @acr.validation_rules_satisfied? || @acr.certificate_content.expired?
                  @result.validation_document[:links][:upload] = true
                end

                unless @acr.validation.validation_histories.blank?
                  @result.validation_document[:links][:manage] = true
                  @result.validation_document[:history] = {}
                  @acr.validation.validation_histories.each do |vh|
                    @result.validation_document[:history][vh.id] = vh
                  end
                end
              end
            end
          end

          if @acr.subject
            @result.visit = @acr.subject.gsub(/^\*\./, "").downcase
          end

          unless @acr.certificate_content.blank?
            @result.contacts = {}
            CertificateContent::CONTACT_ROLES.each do |role|
              @result.contacts[role] = @acr.certificate_content.certificate_contacts.detect(&"is_#{role}?".to_sym)
            end
          end

          @result.certificate_contents = {}
          @acr.certificate_contents.order('created_at DESC').each do |cc|
            @result.certificate_contents[cc.label] = {}
            @result.certificate_contents[cc.label][:server_software] = cc.server_software.try(:title)
            @result.certificate_contents[cc.label][:current] = cc == @acr.certificate_content

            @result.certificate_contents[cc.label][:csr] = {}
            csr = cc.csr
            @result.certificate_contents[cc.label][:csr][:body] = csr.body
            @result.certificate_contents[cc.label][:csr][:created_at] = csr.created_at.strftime("%b %d, %Y %R %Z")

            @result.certificate_contents[cc.label][:sc] = {}
            sc = cc.csr.try(:signed_certificate)
            @result.certificate_contents[cc.label][:sc][:body] = sc.body
            @result.certificate_contents[cc.label][:sc][:serial] = sc.serial
            @result.certificate_contents[cc.label][:sc][:created_at] = sc.created_at.strftime("%b %d, %Y %R %Z")
            @result.certificate_contents[cc.label][:sc][:decoded] = sc.decoded
            @result.certificate_contents[cc.label][:sc][:subject_alternative_names] = sc.subject_alternative_names

            # @result.certificate_contents[cc.label]['permitted_to'] = permitted_to!(:create, SignedCertificate.new)
          end

          @result.api_commands = {}
          @result.api_commands[:is_server] = @acr.certificate.is_server?
          @result.api_commands[:comm_name] = Settings.community_name
          @result.api_commands[:is_test] = @acr.is_test

          @result.api_commands[:products] = []
          serial_list = ['evucc256sslcom', 'ucc256sslcom', 'ov256sslcom', 'ev256sslcom', 'dv256sslcom', 'wc256sslcom', 'basic256sslcom']
          serial_list.push('premium256sslcom') if DEPLOYMENT_CLIENT=~/www.ssl.com/
          serial_list.each do |serial|
            c = Certificate.find_by_serial(serial)
            @result.api_commands[:products].push('"' + c.api_product_code + '"' + ' - ' + c.title)
          end

          @result.api_commands[:command] = {}
          @result.api_commands[:command][:command_1] = {}
          @result.api_commands[:command][:command_1][:key] = @acr.csr ? 'Status/Retrieve' : 'Status'
          @result.api_commands[:command][:command_1][:doc_url] =
              'http://docs.sslcomapi.apiary.io/#get-%2Fcertificate%2F%7Bref%7D%2F%7B%3Fquery_type%2Cresponse_type%2Cresponse_encoding%7D'
          @result.api_commands[:command][:command_1][:command_str] = @acr.to_api_string(action: 'show', domain_override: api_domain(@acr))

          @result.api_commands[:command][:command_2] = {}
          @result.api_commands[:command][:command_2][:key] = 'List Orders'
          @result.api_commands[:command][:command_2][:doc_url] =
              'http://docs.sslcomapi.apiary.io/#get-%2Fcertificate%2F%7Bref%7D%2F%7B%3Fquery_type%2Cresponse_type%2Cresponse_encoding%7D'
          @result.api_commands[:command][:command_2][:command_str] = @acr.to_api_string(action: 'index', domain_override: api_domain(@acr))

          @result.api_commands[:command][:command_3] = {}
          @result.api_commands[:command][:command_3][:key] = 'New Order W/O CSR'
          @result.api_commands[:command][:command_3][:doc_url] = 'http://docs.sslcomapi.apiary.io/#post-%2Fcertificates'
          @result.api_commands[:command][:command_3][:command_str] = @acr.to_api_string(action: 'create', domain_override: api_domain(@acr))

          @result.api_commands[:command][:command_4] = {}
          @result.api_commands[:command][:command_4][:key] = 'List DCV Methods W/O CSR'
          @result.api_commands[:command][:command_4][:doc_url] =
              'http://docs.sslcomapi.apiary.io/#get-%2Fcertificate%2F%7Bref%7D%2Fvalidations%2Fmethods%7B%3Faccount_key%2Csecret_key%7D'
          @result.api_commands[:command][:command_4][:command_str] =
              @acr.to_api_string(action: 'dcv_methods_wo_csr', domain_override: api_domain(@acr))

          if @acr.certificate_content.registrant
            if @acr.csr
              @result.api_commands[:command][:command_5] = {}
              @result.api_commands[:command][:command_5][:key] = 'New Order W/ CSR'
              @result.api_commands[:command][:command_5][:doc_url] = 'http://docs.sslcomapi.apiary.io/#post-%2Fcertificates'
              @result.api_commands[:command][:command_5][:command_str] = @acr.to_api_string(action: 'create_w_csr', domain_override: api_domain(@acr))

              @result.api_commands[:command][:command_6] = {}
              @result.api_commands[:command][:command_6][:key] = 'List DCV Methods W/ CSR'
              @result.api_commands[:command][:command_6][:doc_url] = 'http://docs.sslcomapi.apiary.io/#post-%2Fcertificates%2Fvalidations%2Fcsr_hash'
              @result.api_commands[:command][:command_6][:command_str] = @acr.to_api_string(action: 'dcv_methods_w_csr', domain_override: api_domain(@acr))

              @result.api_commands[:command][:command_7] = {}
              @result.api_commands[:command][:command_7][:key] = 'Update DCV'
              @result.api_commands[:command][:command_7][:doc_url] = 'http://docs.sslcomapi.apiary.io/#put-%2Fcertificate%2F%7Bref%7D'
              @result.api_commands[:command][:command_7][:command_str] = @acr.to_api_string(action: 'update_dcv', domain_override: api_domain(@acr))
            end
            if @acr.external_order_number
              @result.api_commands[:command][:command_8] = {}
              @result.api_commands[:command][:command_8][:key] = 'Process CSR or Reissue'
              @result.api_commands[:command][:command_8][:doc_url] = 'http://docs.sslcomapi.apiary.io/#put-%2Fcertificate%2F%7Bref%7D'
              @result.api_commands[:command][:command_8][:command_str] = @acr.to_api_string(action: 'update', domain_override: api_domain(@acr))

              @result.api_commands[:command][:command_9] = {}
              @result.api_commands[:command][:command_9][:key] = 'Revoke'
              @result.api_commands[:command][:command_9][:doc_url] =
                  'http://docs.sslcomapi.apiary.io/#reference/ssl-certificates/certificate-order/revoke-certificate'
              @result.api_commands[:command][:command_9][:command_str] = @acr.to_api_string(action: 'revoke', domain_override: api_domain(@acr))
            end
          end

          # TODO: In case of Admin.
        end

        render(:template => @template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
    end
  rescue => e
    render_500_error e
  end

  def download_v1_4
    send_file "#{Rails.root}/tmp/certificate/#{params[:file_name]}"
  end

  def show_v1_4
    @template = "api_certificate_requests/show_v1_4"

    if @result.save
      @acr = @result.find_certificate_order

      if @acr.is_a?(CertificateOrder) && @acr.errors.empty?
        @result.order_date = @acr.created_at
        @result.order_status = @acr.status
        @result.registrant = @acr.certificate_content.registrant.to_api_query if (@acr.certificate_content && @acr.certificate_content.registrant)
        @result.contacts = @acr.certificate_content.certificate_contacts if (@acr.certificate_content && @acr.certificate_content.certificate_contacts)
        @result.validations = @result.validations_from_comodo(@acr) #'validations' kept executing twice so it was renamed to 'validations_from_comodo'
        @result.description = @acr.description
        @result.product = @acr.certificate.api_product_code
        @result.subscriber_agreement = @acr.certificate.subscriber_agreement_content if @result.show_subscriber_agreement=~/[Yy]/
        @result.external_order_number = @acr.ext_customer_ref
        @result.server_software = @acr.server_software.id if @acr.server_software

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
          @result.site_seal_code = ERB::Util.json_escape(render_to_string(
            partial: 'site_seals/site_seal_code.html.haml',
            locals: {co: @acr},
            layout: false
          ))
        elsif (@acr.csr)
          @result.certificates = @acr.csr.body
          @result.common_name = @acr.csr.common_name
        end

        render(:template => @template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
    end
  rescue => e
    render_500_error e
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
    render_500_error e
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
    @template   = "api_certificate_requests/index_v1_4"
    @result.end = DateTime.now if @result.end.blank?
    client_app  = params[:client_app]

    if @result.save
      @orders = @result.find_certificate_orders(params[:search])

      page     = params[:page] || 1
      per_page = params[:per_page] || PER_PAGE_DEFAULT
      @acrs    = paginate @orders, per_page: per_page.to_i, page: page.to_i

      if @acrs.is_a?(ActiveRecord::Relation)
        @results = []
        @acrs.each do |acr|
          c = acr.certificate
          sc = acr.signed_certificate
          cc = acr.certificate_content

          result = ApiCertificateRetrieve.new(ref: acr.ref)
          result.order_date =   acr.created_at
          result.order_status = acr.status
          result.domains =      acr.all_domains
          result.description =  acr.description
          result.common_name =  sc ? sc.common_name : nil
          result.product_type = c.product
          result.period =       acr.certificate_contents.first.duration

          if client_app
            result.expiration_date = sc ? sc.expiration_date : nil
          else
            result.registrant = cc.registrant.to_api_query if (cc && cc.registrant)
            result.validations = result.validations_from_comodo(acr) #'validations' kept executing twice so it was renamed to 'validations_from_comodo'

            if c.is_ucc?
              result.domains_qty_purchased = acr.purchased_domains('all').to_s
              result.wildcard_qty_purchased = acr.purchased_domains('wildcard').to_s
            else
              result.domains_qty_purchased = '1'
              result.wildcard_qty_purchased = c.is_wildcard? ? '1' : '0'
            end

            if (sc && result.query_type!='order_status_only')
              signed_certificate_format = sc.to_format(
                  response_type:     @result.response_type, #assume comodo issued cert
                  response_encoding: @result.response_encoding
              )
              result.certificates = signed_certificate_format || sc.to_nginx
              result.subject_alternative_names = sc.subject_alternative_names
              result.effective_date = sc.effective_date
              result.expiration_date = sc.expiration_date
              result.algorithm = sc.is_SHA2? ? 'SHA256' : 'SHA1'
              result.site_seal_code = ERB::Util.json_escape(render_to_string(
                partial: 'site_seals/site_seal_code.html.haml',
                locals: {co: acr},
                layout: false)
              )
            end
          end
          @results << result
        end
        if client_app
          render json: serialize_models(@results,
            meta: { orders_count: @orders.count, page: page, per_page: per_page }
          )
        else
          render(template: @template) and return
        end
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
    end
  rescue => e
    render_500_error e
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

  def pretest_v1_4
    @template = "api_certificate_requests/pretest_v1_4"
    if @result.save && find_certificate_order.is_a?(CertificateOrder)
      http_to_s = dcv_verify(params[:protocol])
      @result.is_passed = http_to_s

      render_200_status_noschema
    end
  rescue => e
    render_500_error e
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
    render_500_error e
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
          ([@acr.csr.common_name]+(@result.domains || [])).compact.map(&:downcase).uniq.each do |domain|
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
    render_500_error e
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
              when "retrieve_v1_3", "show_v1_4", "index_v1_4", "detail_v1_4"
                ApiCertificateRetrieve
              when "api_parameters_v1_4"
                ApiParameters
              when "quote"
                ApiCertificateQuote
              when "dcv_email_resend_v1_3"
                ApiDcvEmailResend
              when "dcv_emails_v1_3", "dcv_revoke_v1_3"
                ApiDcvEmails
              when "dcv_methods_v1_4", "dcv_revoke_v1_3", "dcv_methods_csr_hash_v1_4", "pretest_v1_4"
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

  def csr
    @csr || @certificate_order.csr
  end

  def dcv_verify(protocol)
    prepend=""
    begin
      Timeout.timeout(Surl::TIMEOUT_DURATION) do
        if protocol=="https"
          uri = URI.parse(dcv_url(true,prepend))
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          request = Net::HTTP::Get.new(uri.request_uri)
          r = http.request(request).body
        elsif protocol=="cname"
          txt = Resolv::DNS.open do |dns|
            records = dns.getresources(cname_origin, Resolv::DNS::Resource::IN::CNAME)
          end
          return cname_destination==txt.last.name.to_s
        else
          r=open(dcv_url(false,prepend), redirect: false).read
        end
        return true if !!(r =~ Regexp.new("^#{csr.sha2_hash}") && r =~ Regexp.new("^comodoca.com") &&
            (csr.unique_value.blank? ? true : r =~ Regexp.new("^#{csr.unique_value}")))
      end
    rescue Exception=>e
      if csr.common_name=~/\A\*/ && prepend.blank? && protocol!="cname" #do another go round for wildcard by prepending www.
        prepend="www."
        retry
      end
      return false
    end
  end

  def dcv_url(secure=false, prepend="")
    "http#{'s' if secure}://#{prepend+non_wildcard_name}/.well-known/pki-validation/#{csr.md5_hash}.txt"
  end

  def cname_origin
    "#{csr.dns_md5_hash}.#{non_wildcard_name}"
  end

  def cname_destination
    "#{csr.dns_sha2_hash}.comodoca.com"
  end

  def non_wildcard_name
    csr.common_name.gsub(/\A\*\./, "").downcase
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

  def certificate_type(certificate_order=nil)
    if certificate_order.is_a?(CertificateOrder)
      unless Order.unscoped{certificate_order.order}.preferred_migrated_from_v2
        certificate_order.certificate.description["certificate_type"]
      else
        certificate_order.preferred_v2_product.description.gsub /[Cc]ertificate\z/, ''
      end
    end
  end

  def api_domain(certificate_order=nil)
    unless certificate_order.blank?
      if Rails.env=~/production/i
        "https://" + (certificate_order.is_test ? Settings.test_api_domain : Settings.api_domain)
      else
        "https://" + (certificate_order.is_test ? Settings.dev_test_api_domain : Settings.dev_api_domain) +":3000"
      end
    else
      if is_sandbox?
        Rails.env=~/production/i ? "https://#{Settings.test_api_domain}" : "https://#{Settings.dev_test_api_domain}:3000"
      else
        Rails.env=~/production/i ? "https://#{Settings.api_domain}" : "https://#{Settings.dev_api_domain}:3000"
      end
    end
  end

  def certificate_file(type, certificate_order)
    path = "#{Rails.root}/tmp/certificate/"
    unless File.directory?(path)
      FileUtils.mkdir_p(path)
    end

    if type === 'pkcs'
      data = certificate_order.signed_certificate.to_pkcs7
      path += certificate_order.signed_certificate.nonidn_friendly_common_name + '.p7b'
      out_file = File.open(path, 'w')
      out_file.puts(data)
      out_file.close
    elsif type === 'nginx'
      data = certificate_order.signed_certificate.to_nginx
      path += certificate_order.signed_certificate.nonidn_friendly_common_name + '.chained.crt'
      out_file = File.new(path, 'w')
      out_file.puts(data)
      out_file.close
    elsif type === 'ca_bundle'
      file = certificate_order.signed_certificate.ca_bundle
      path += certificate_order.signed_certificate.nonidn_friendly_common_name + '.ca-bundle'
      FileUtils.mv(file, path)
    elsif type === 'whm_bundle'
      file = certificate_order.signed_certificate.zipped_whm_bundle
      path += certificate_order.signed_certificate.nonidn_friendly_common_name + '.zip'
      FileUtils.mv(file, path)
    elsif type === 'apache_bundle'
      file = certificate_order.signed_certificate.zipped_apache_bundle
      path += certificate_order.signed_certificate.nonidn_friendly_common_name + '.zip'
      FileUtils.mv(file, path)
    elsif type === 'amazon_bundle'
      file = certificate_order.signed_certificate.zipped_amazon_bundle
      path += certificate_order.signed_certificate.nonidn_friendly_common_name + '.zip'
      FileUtils.mv(file, path)
    elsif type === 'other'
      file = certificate_order.certificate_content.csr.signed_certificate.
          create_signed_cert_zip_bundle({components: true, is_windows: false})
      path += certificate_order.friendly_common_name + '.zip'
      FileUtils.mv(file, path)
    end

    path[(path.rindex('/') + 1)..path.length]
  end
end
