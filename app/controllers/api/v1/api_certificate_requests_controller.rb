# frozen_string_literal: false

class Api::V1::ApiCertificateRequestsController < Api::V1::APIController
  prepend_view_path 'app/views/api/v1/api_certificate_requests'
  include ActionController::Helpers
  helper SiteSealsHelper
  before_action :set_database, if: -> { request.host.match?(/^sandbox/) || request.host.match?(/^sws-test/) || request.host.match?(/ssl.local$/) }
  before_action :set_test, :record_parameters, except: %i[scan analyze download_v1_4]
  after_action :notify_saved_result, except: %i[create_v1_4 download_v1_4]
  before_action :set_certificate_order, only: [:update_v1_4]
  before_action :verify_dcv_method, only: [:update_v1_4]

  # parameters listed here made available as attributes in @result
  wrap_parameters ApiCertificateRequest, include: [*(
    ApiCertificateRequest::ACCESSORS +
    ApiCertificateRequest::CREATE_ACCESSORS_1_4 +
    ApiCertificateRequest::RETRIEVE_ACCESSORS +
    ApiCertificateRequest::DETAILED_ACCESSORS +
    ApiCertificateRequest::REPROCESS_ACCESSORS +
    ApiCertificateRequest::REVOKE_ACCESSORS +
    ApiCertificateRequest::DCV_EMAILS_ACCESSORS +
    ApiCertificateRequest::CERTIFICATE_ENROLLMENT_ACCESSORS
  ).uniq]

  ORDERS_DOMAIN = "https://#{Settings.community_domain}".freeze
  SANDBOX_DOMAIN = 'https://sandbox.ssl.com'.freeze
  SCAN_COMMAND = ->(parameters, url){ `echo QUIT | cipherscan/cipherscan #{parameters} #{url}` }
  ANALYZE_COMMAND = ->(parameters, url){ `echo QUIT | cipherscan/analyze.py #{parameters} #{url}` }

  def notify_saved_result
    @rendered = render_to_string(template: @template)
    unless @rendered.is_a?(String) && @rendered.include?('errors')
      # commenting this out, it's causing encoding issues and can grow out of control
      # @result.update_attribute :response, @rendered
      OrderNotifier.api_executed(@rendered, request.host_with_port).deliver if @rendered && !Settings.send_api_calls.blank?
    end
  end

  # set which parameters will be displayed via the api response
  def set_result_parameters(result, acr)
    cc                     = acr.certificate_contents.last # need to reload to get certs
    ssl_slug               = acr.ssl_account.to_slug
    result.ref             = acr.ref
    result.order_status ||= acr.status # using ||= because status might have been set from CAA problems
    result.order_amount = acr.order.amount.format
    domain = api_result_domain(acr)
    result.external_order_number = acr.ext_customer_ref
    result.certificate_url = domain + certificate_order_path(ssl_slug, acr)
    result.receipt_url     = domain + order_path(ssl_slug, acr.order)
    result.smart_seal_url  = domain + certificate_order_site_seal_path(ssl_slug, acr.ref)
    result.validation_url  = domain + certificate_order_validation_path(ssl_slug, acr)
    result.registrant      = cc.registrant.to_api_query if cc&.registrant
    result.certificates    = cc.x509_certificates.map(&:to_s).join("\n") if cc.x509_certificates
    result.certificate_contents = cc.to_api_query
  end

  def create_v1_4
    set_template 'create_v1_4'
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
        InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
      end
    end
    render_200_status
  rescue StandardError => e
    render_500_error e
  end

  def retrieve_signed_certificates
    set_template 'retreive_signed_certificates'

    if @result.valid? && @result.save
      @result.signed_certificates = []
      @acr = @result.find_signed_certificates_by_public_key

      @acr.each do |sc|
        @result.signed_certificates << sc.as_json['signed_certificate']
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
    end

    render_200_status
  rescue => e
    render_500_error e
  end

  def revoke_v1_4
    set_template 'revoke_v1_4'
    if @result.valid? && @result.save
      co = @result.find_certificate_order
      @acr = @result.find_signed_certificates(co)
      if @acr.is_a?(Array) && @result.errors.empty?
        if @result.serials.blank? # revoke the entire order
          co.revoke!(@result.reason,@result.api_credential)
        else # revoke specific certs
          @acr.each do |signed_certificate|
            SystemAudit.create(
              owner: @result.api_credential,
              target: signed_certificate,
              notes: "api revocation from ip address #{request.remote_ip}",
              action: 'revoked'
            )
            signed_certificate.revoke! @result.reason
          end

        end
        @result.status = 'revoked'
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
    end
    render_200_status
  rescue => e
    render_500_error e
  end

  def generate_certificate_v1_4
    set_template "generate_certificate_v1_4"

    if @result.valid? && @result.save
      co = @result.find_certificate_order

      options={csr: params[:csr]}
      unless co.certificate_content.csr.blank?
        cc_params = co.certificate_content.attributes.except(*%w{id created_at updated_at label ref})
        new_cc = CertificateContent.new(cc_params)
        new_cc.save if new_cc.valid?
        if new_cc.preferred_pending_issuance?
          new_cc.write_preference("pending_issuance", false)
          cc.preferred_pending_issuance_will_change!
        end
        new_cc.create_registrant(
            co.certificate_content.registrant.attributes.except(*CertificateOrder::ID_AND_TIMESTAMP)
        ) if co.certificate_content.registrant
        new_cc.create_locked_registrant(
            co.certificate_content.locked_registrant.attributes.except(*CertificateOrder::ID_AND_TIMESTAMP)
        ) if co.certificate_content.locked_registrant

        options[:certificate_content] = new_cc
      end

      generated_certificate = SslcomCaApi.apply_for_certificate(co, options)
      unless generated_certificate.nil?
        if res = generated_certificate.x509_certificates
          co_token = co.certificate_order_tokens.where(token: params[:token], status: nil, is_expired: false).last
          co_token.update_attribute(:is_expired, true) if co_token
          co.update_attribute(:request_status, '')

          cert_chain = ""
          res.each do |cert|
            cert_chain += cert.to_s
          end

          @result.cert_results = cert_chain
          @result.cert_common_name = (res.first.subject.common_name ?
                                          res.first.subject.common_name.force_encoding('UTF-8') :
                                          res.first.serial.to_s).gsub(/[\s\.\*\(\)]/,"_").downcase + '.crt'
        end
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
    end

    render_200_status
  rescue => e
    render_500_error e
  end

  def certificate_enrollment_order
    set_template "certificate_enrollment_order"

    if @result.valid? && @result.save
      if @result.certificate_enrollment
        @result.is_ordered = true
      else
        @result.is_ordered = false
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
    end

    render_200_status
  rescue => e
    render_500_error e
  end

  def replace_v1_4
    set_template "replace_v1_4"

    if @result.csr_obj && !result.csr_obj.valid?
      @result = @result.csr_obj
    else
      if @result.save
        if @acr = @result.replace_certificate_order
          @csr = @acr.csr

          if @acr.is_a?(CertificateOrder) && @acr.errors.empty?
            if @acr.certificate_content.csr && @result.debug=="true"
              ccr = @acr.certificate_content.csr.ca_certificate_requests.last
              @result.api_request=ccr.parameters
              @result.api_response=ccr.response
            end

            #Send validation email unless ca_id is nil
            unless @acr.certificate_content.ca_id.nil?
              cnames = @acr.certificate_content.certificate_names.includes(:domain_control_validations)
              email_for_identifier = ''
              identifier = ''
              email_list = []
              identifier_list = []
              domain_ary = []
              domain_list = []
              emailed_domains = []

              cnames.each do |cn|
                dcv = cn.domain_control_validations.last

                unless dcv.identifier_found
                  if dcv.dcv_method == 'email'
                    if DomainControlValidation.approved_email_address? CertificateName.candidate_email_addresses(
                        cn.non_wildcard_name), dcv.email_address
                      if dcv.email_address != email_for_identifier
                        if domain_list.length > 0
                          domain_ary << domain_list
                          email_list << email_for_identifier
                          identifier_list << identifier
                          domain_list = []
                        end

                        identifier = DomainControlValidation.generate_identifier
                        email_for_identifier = dcv.email_address
                      end

                      domain_list << cn.name
                      emailed_domains << cn.name
                      dcv.update_attribute(:identifier, identifier)
                    end
                  else
                    if cn.dcv_verify(dcv.dcv_method)
                      dcv.satisfy! unless dcv.satisfied?
                    end
                  end
                end
              end

              unless identifier == ''
                ssl_slug = @result.api_credential.ssl_account.ssl_slug || @result.api_credential.ssl_account.acct_number

                domain_ary << domain_list
                email_list << email_for_identifier
                identifier_list << identifier

                email_list.each_with_index do |value, key|
                  OrderNotifier.dcv_email_send(value, identifier_list[key], domain_ary[key], nil, ssl_slug).deliver
                end
              end
            end

            set_result_parameters(@result, @acr)
            @result.debug=(@result.parameters_to_hash["debug"]=="true") # && @acr.admin_submitted = true
          else
            @result = @acr #so that rabl can report errors
          end
        end
      else
        InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
      end
    end
    render_200_status
  rescue => e
    render_500_error e
  end

  def api_resend_domain_validation_v1_4
    set_template "api_resend_domain_validation_v1_4"

    if @result.save
      if @acr = @result.resend_domain_validation
        if @acr.is_a?(CertificateOrder) && @acr.errors.empty?
          @result.success_message = "Successfully retried domain validation for certificate order ref #{@acr.ref}"
        elsif @acr.is_a?(String) && @acr == "incorrect_state"
          @result.error_message = "Error: certificate order #{@acr.ref} is not in pending validation state."
        elsif @acr.is_a?(String) && @acr == "empty_dcv"
          @result.error_message = "Error: certificate order #{@acr.ref} domain validation has never been performed yet."
        else
          @result = @acr
        end
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: "ssl.com"
    end
    render_200_status
  rescue => e
    render_500_error e
  end

  def update_v1_4
    set_template 'update_v1_4'

    if @result.csr_obj && !@result.csr_obj.valid?
      # we do this sloppy maneuver because the rabl template only reports errors
      @result = @result.csr_obj
    else
      if @result.save # save the api request
        if @acr = @result.update_certificate_order
          @csr = @acr.csr
          # successfully charged
          if @acr.is_a?(CertificateOrder) && @acr.errors.empty?
            @acr.unchain_comodo if @acr.signed_certificate_duration_delta > 1
            if @acr.certificate_content.csr && @result.debug == 'true'
              ccr = @acr.certificate_content.csr.ca_certificate_requests.first
              @result.api_request = ccr.parameters
              @result.api_response = ccr.response
            end

            # Send validation email unless ca_id is nil
            unless @acr.certificate_content.ca_id.nil?
              cnames = @acr.certificate_content.certificate_names.includes(:domain_control_validations, :certificate_content)
              email_for_identifier = ''
              identifier = ''
              email_list = []
              identifier_list = []
              domain_ary = []
              domain_list = []
              emailed_domains = []
              # succeeded_domains = []
              # failed_domains = []

              cnames.each do |cn|
                dcv = cn.domain_control_validations.last
                dcv ||= cn.domain_control_validations.create(dcv_method: dcv_param, candidate_addresses: cn.name) if dcv_param.match? /^acme/i
                if dcv && !dcv.identifier_found # TODO DRY and apply with app/controllers/validations_controller.rb:305
                  if dcv.dcv_method == 'email'
                    if DomainControlValidation.approved_email_address? CertificateName.candidate_email_addresses(cn.non_wildcard_name), dcv.email_address
                      if dcv.email_address != email_for_identifier
                        if domain_list.length > 0
                          domain_ary << domain_list
                          email_list << email_for_identifier
                          identifier_list << identifier
                          domain_list = []
                        end
                        identifier = (SecureRandom.hex(8) + Time.now.to_i.to_s(32))[0..19]
                        email_for_identifier = dcv.email_address
                      end

                      domain_list << cn.name
                      emailed_domains << cn.name
                      dcv.update_attribute(:identifier, identifier)
                    end
                  else
                    cn.dcv_verify_async(dcv.dcv_method)
                  end
                end
              end

              if identifier.blank?
                @acr.apply_for_certificate unless dcv_param.match? /^acme/
              else
                ssl_slug = @result.api_credential.ssl_account.ssl_slug || @result.api_credential.ssl_account.acct_number

                domain_ary << domain_list
                email_list << email_for_identifier
                identifier_list << identifier

                email_list.each_with_index do |value, key|
                  OrderNotifier.dcv_email_send(value, identifier_list[key], domain_ary[key], nil, ssl_slug).deliver
                end
              end
            end

            set_result_parameters(@result, @acr)
            @result.debug = (@result.parameters_to_hash['debug'] == 'true') # && @acr.admin_submitted = true
          else
            @result = @acr # so that rabl can report errors
          end
        end
      else
        InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
      end
    end
    render_200_status
  rescue StandardError => e
    render_500_error e
  end

  def callback_v1_4
    set_template 'callback_v1_4'

    if @result.save
      @acr = @result.find_certificate_order
      if @acr.is_a?(CertificateOrder) && @acr.errors.empty?
        req,res = @acr.certificate_content.callback(@result.callback)
        @result.callback_hook=res.body
        @result.response=res
      else
        @result = @acr unless @acr.blank? # if @acr is blank then order not found
      end

    else
      InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
    end
    render_200_status
  rescue => e
    render_500_error e
  end

  def contacts_v1_4
    @template = "api_certificate_requests/contacts_v1_4"

    if @result.save
      if @acr = @result.update_certificate_content_contacts
        @result.success_message = 'Contacts were successfully updated.'
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
    end
    render_200_status
  rescue => e
    render_500_error e
  end

  def dcv_validate_v1_4
    set_template "success_retrieve_v1_3"
    if @result.save
      if @certificate_order.is_a?(CertificateOrder)
        @certificate_order.api_validate(@result)
        @result.order_status = @certificate_order.status
        @result.update_attribute :response, render_to_string(:template => @template)
        render(:template => @template) and return
      else
        InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
      end
    end
    render action: :create_v1_3
  end

  def detail_v1_4
    set_template "detail_v1_4"

    if @result.save
      @acr = @result.find_certificate_order

      if @acr.is_a?(CertificateOrder) && @acr.errors.empty?
        @result.menu = {}

        @result.menu[:certificate_details_tab] = true
        @result.menu[:validation_status_tab] = true
        @result.menu[:smart_seal_tab] = true
        @result.menu[:transaction_receipt_tab] = true

        @result.is_admin = false

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

        if @result.menu[:certificate_details_tab]
          @result.cert_details = {}
          @result.cert_details[:main] = {}
          @result.cert_details[:main][:subject] = @acr.signed_certificate ? @acr.signed_certificate.common_name : nil
          @result.cert_details[:main][:order_status] = @acr.status
          @result.cert_details[:main][:order_date] = @acr.created_at
          @result.cert_details[:main][:expiry_date] = @acr.signed_certificate ?
                                           @acr.signed_certificate.expiration_date : nil

          @result.cert_details[:certificate_content] = {}
          @result.cert_details[:certificate_content][:csr_blank] = @acr.certificate_content.csr.blank?
          @result.cert_details[:certificate_content][:fields] = {}
          @result.cert_details[:certificate_content][:fields][:is_signed] = true

          if @acr.certificate_content.csr.signed_certificate.blank?
            csr = @acr.certificate_content.csr
            @result.cert_details[:certificate_content][:fields][:is_signed] = false
            @result.cert_details[:certificate_content][:fields][:organization] = csr.organization
            @result.cert_details[:certificate_content][:fields][:organization_unit] = csr.organization_unit
            @result.cert_details[:certificate_content][:fields][:locality] = csr.locality
            @result.cert_details[:certificate_content][:fields][:state] = csr.state
            @result.cert_details[:certificate_content][:fields][:country] = csr.country
          else
            sc = @acr.certificate_content.csr.signed_certificate
            @result.cert_details[:certificate_content][:fields][:algorithm] = sc.signature_algorithm
            @result.cert_details[:certificate_content][:fields][:decoded] = sc.decoded
          end

          @result.cert_details[:in_limit] = (@acr.certificate_duration(:days).to_i > @acr.max_duration) && (@acr.created_at > Date.parse('Apr 1 2015'))
          @result.cert_details[:registrant] = @acr.certificate_content.registrant.to_api_query

          if @acr.certificate_content.issued? && !@acr.certificate_content.expired?
            csr, sc = @acr.csr, @acr.signed_certificate

            @result.cert_details[:download] = [
                ["iis7", "Microsoft IIS (*.p7b)", certificate_file("pkcs", @acr), SignedCertificate::IIS_INSTALL_LINK],
                ["cpanel", "WHM/cpanel", certificate_file("whm_bundle", @acr), SignedCertificate::CPANEL_INSTALL_LINK],
                ["apache", "Apache", certificate_file("apache_bundle", @acr), SignedCertificate::APACHE_INSTALL_LINK],
                ["amazon", "Amazon", certificate_file("amazon_bundle", @acr), SignedCertificate::AMAZON_INSTALL_LINK],
                ["nginx", "Nginx", certificate_file("nginx", @acr), SignedCertificate::NGINX_INSTALL_LINK],
                ["v8_nodejs", "V8+Node.js", certificate_file("nginx", @acr), SignedCertificate::V8_NODEJS_INSTALL_LINK],
                ["java", "Java/Tomcat", certificate_file("other", @acr), SignedCertificate::JAVA_INSTALL_LINK],
                ["other", "Other platforms", certificate_file("other", @acr), SignedCertificate::OTHER_INSTALL_LINK],
                ["bundle", "CA bundle (intermediate certs)", certificate_file("ca_bundle", @acr), SignedCertificate::OTHER_INSTALL_LINK]
            ]
          end

          unless (@acr.certificate_content.csr.blank? ||
              (!@acr.certificate_content.show_validation_view? && @acr.is_test?))
            if @acr.certificate_content.pending_validation?
              @result.cert_details[:domain_validation] = true
            end
            unless @acr.certificate.is_dv?
              @result.cert_details[:validation_document] = {}

              unless @acr.certificate_content.blank? ||
                  @acr.certificate_content.new? ||
                  @acr.certificate_content.csr_submitted? ||
                  @acr.certificate_content.info_provided? ||
                  @acr.expired?
                @result.cert_details[:validation_document][:links] = {}
                @result.cert_details[:validation_document][:links][:status] = true

                unless @acr.validation_rules_satisfied? || @acr.certificate_content.expired?
                  @result.cert_details[:validation_document][:links][:upload] = true
                end

                unless @acr.validation.validation_histories.blank?
                  @result.cert_details[:validation_document][:links][:manage] = true
                  @result.cert_details[:validation_document][:history] = []

                  @acr.validation.validation_histories.each do |vh|
                    tmp = {}
                    tmp[:id] = vh.id
                    tmp[:preview] = getDocumentsPath(vh, vh.document_url(:preview)) if vh.document_content_type =~ %r(image)
                    tmp[:doc_url] = getDocumentsPath(vh, vh.document_url)
                    tmp[:file_name] = vh.document_file_name.shorten(25, false)

                    @result.cert_details[:validation_document][:history] << tmp
                  end
                end
              end
            end
          end

          if @acr.subject
            @result.cert_details[:visit] = @acr.subject.gsub(/^\*\./, "").downcase
          end

          unless @acr.certificate_content.blank?
            @result.cert_details[:contacts] = {}
            CertificateContent::CONTACT_ROLES.each do |role|
              @result.cert_details[:contacts][role] = @acr.certificate_content.certificate_contacts.detect(&"is_#{role}?".to_sym)
            end
          end

          @result.cert_details[:certificate_contents] = {}
          @acr.certificate_contents.order('created_at DESC').each do |cc|
            @result.cert_details[:certificate_contents][cc.label] = {}
            @result.cert_details[:certificate_contents][cc.label][:server_software] = cc.server_software.try(:title)
            @result.cert_details[:certificate_contents][cc.label][:current] = cc == @acr.certificate_content

            @result.cert_details[:certificate_contents][cc.label][:csr] = {}
            csr = cc.csr
            @result.cert_details[:certificate_contents][cc.label][:csr][:body] = csr.body
            @result.cert_details[:certificate_contents][cc.label][:csr][:created_at] = csr.created_at.strftime("%b %d, %Y %R %Z")

            @result.cert_details[:certificate_contents][cc.label][:sc] = {}
            sc = cc.csr.try(:signed_certificate)
            if sc
              @result.cert_details[:certificate_contents][cc.label][:sc][:body] = sc.body
              @result.cert_details[:certificate_contents][cc.label][:sc][:serial] = sc.serial
              @result.cert_details[:certificate_contents][cc.label][:sc][:created_at] = sc.created_at.strftime("%b %d, %Y %R %Z")
              @result.cert_details[:certificate_contents][cc.label][:sc][:decoded] = sc.decoded
              @result.cert_details[:certificate_contents][cc.label][:sc][:subject_alternative_names] = sc.subject_alternative_names
            end
          end

          @result.cert_details[:api_commands] = {}
          @result.cert_details[:api_commands][:is_server] = @acr.certificate.is_server?
          @result.cert_details[:api_commands][:comm_name] = Settings.community_name
          @result.cert_details[:api_commands][:is_test] = @acr.is_test

          @result.cert_details[:api_commands][:products] = []
          serial_list = ['evucc256sslcom', 'ucc256sslcom', 'ov256sslcom', 'ev256sslcom', 'dv256sslcom', 'wc256sslcom', 'basic256sslcom']
          serial_list.push('premium256sslcom') if DEPLOYMENT_CLIENT =~ Regexp.new(Settings.portal_domain)
          serial_list.each do |serial|
            c = Certificate.find_by_serial(serial)
            @result.cert_details[:api_commands][:products].push('"' + c.api_product_code + '"' + ' - ' + c.title)
          end

          @result.cert_details[:api_commands][:command] = {}
          @result.cert_details[:api_commands][:command][:command_1] = {}
          @result.cert_details[:api_commands][:command][:command_1][:key] = @acr.csr ? 'Status/Retrieve' : 'Status'
          @result.cert_details[:api_commands][:command][:command_1][:doc_url] =
              'http://docs.sslcomapi.apiary.io/#get-%2Fcertificate%2F%7Bref%7D%2F%7B%3Fquery_type%2Cresponse_type%2Cresponse_encoding%7D'
          @result.cert_details[:api_commands][:command][:command_1][:command_str] = @acr.to_api_string(action: 'show', domain_override: api_domain(@acr))

          @result.cert_details[:api_commands][:command][:command_2] = {}
          @result.cert_details[:api_commands][:command][:command_2][:key] = 'List Orders'
          @result.cert_details[:api_commands][:command][:command_2][:doc_url] =
              'http://docs.sslcomapi.apiary.io/#get-%2Fcertificate%2F%7Bref%7D%2F%7B%3Fquery_type%2Cresponse_type%2Cresponse_encoding%7D'
          @result.cert_details[:api_commands][:command][:command_2][:command_str] = @acr.to_api_string(action: 'index', domain_override: api_domain(@acr))

          @result.cert_details[:api_commands][:command][:command_3] = {}
          @result.cert_details[:api_commands][:command][:command_3][:key] = 'New Order W/O CSR'
          @result.cert_details[:api_commands][:command][:command_3][:doc_url] = 'http://docs.sslcomapi.apiary.io/#post-%2Fcertificates'
          @result.cert_details[:api_commands][:command][:command_3][:command_str] = @acr.to_api_string(action: 'create', domain_override: api_domain(@acr))

          @result.cert_details[:api_commands][:command][:command_4] = {}
          @result.cert_details[:api_commands][:command][:command_4][:key] = 'List DCV Methods W/O CSR'
          @result.cert_details[:api_commands][:command][:command_4][:doc_url] =
              'http://docs.sslcomapi.apiary.io/#get-%2Fcertificate%2F%7Bref%7D%2Fvalidations%2Fmethods%7B%3Faccount_key%2Csecret_key%7D'
          @result.cert_details[:api_commands][:command][:command_4][:command_str] =
              @acr.to_api_string(action: 'dcv_methods_wo_csr', domain_override: api_domain(@acr))

          if @acr.certificate_content.registrant
            if @acr.csr
              @result.cert_details[:api_commands][:command][:command_5] = {}
              @result.cert_details[:api_commands][:command][:command_5][:key] = 'New Order W/ CSR'
              @result.cert_details[:api_commands][:command][:command_5][:doc_url] = 'http://docs.sslcomapi.apiary.io/#post-%2Fcertificates'
              @result.cert_details[:api_commands][:command][:command_5][:command_str] = @acr.to_api_string(action: 'create_w_csr', domain_override: api_domain(@acr))

              @result.cert_details[:api_commands][:command][:command_6] = {}
              @result.cert_details[:api_commands][:command][:command_6][:key] = 'List DCV Methods W/ CSR'
              @result.cert_details[:api_commands][:command][:command_6][:doc_url] = 'http://docs.sslcomapi.apiary.io/#post-%2Fcertificates%2Fvalidations%2Fcsr_hash'
              @result.cert_details[:api_commands][:command][:command_6][:command_str] = @acr.to_api_string(action: 'dcv_methods_w_csr', domain_override: api_domain(@acr))

              @result.cert_details[:api_commands][:command][:command_7] = {}
              @result.cert_details[:api_commands][:command][:command_7][:key] = 'Update DCV'
              @result.cert_details[:api_commands][:command][:command_7][:doc_url] = 'http://docs.sslcomapi.apiary.io/#put-%2Fcertificate%2F%7Bref%7D'
              @result.cert_details[:api_commands][:command][:command_7][:command_str] = @acr.to_api_string(action: 'update_dcv', domain_override: api_domain(@acr))
            end
            if @acr.external_order_number
              @result.cert_details[:api_commands][:command][:command_8] = {}
              @result.cert_details[:api_commands][:command][:command_8][:key] = 'Process CSR or Reissue'
              @result.cert_details[:api_commands][:command][:command_8][:doc_url] = 'http://docs.sslcomapi.apiary.io/#put-%2Fcertificate%2F%7Bref%7D'
              @result.cert_details[:api_commands][:command][:command_8][:command_str] = @acr.to_api_string(action: 'update', domain_override: api_domain(@acr))

              @result.cert_details[:api_commands][:command][:command_9] = {}
              @result.cert_details[:api_commands][:command][:command_9][:key] = 'Revoke'
              @result.cert_details[:api_commands][:command][:command_9][:doc_url] =
                  'http://docs.sslcomapi.apiary.io/#reference/ssl-certificates/certificate-order/revoke-certificate'
              @result.cert_details[:api_commands][:command][:command_9][:command_str] = @acr.to_api_string(action: 'revoke', domain_override: api_domain(@acr))
            end
          end

          # TODO: In case of Admin.
        end

        if @result.menu[:smart_seal_tab]
          ss = @acr.site_seal

          @result.smart_seal = {}
          @result.smart_seal[:main] = {}
          @result.smart_seal[:main][:subject] = @acr.signed_certificate ? @acr.signed_certificate.common_name : nil
          @result.smart_seal[:main][:cert_status] = certificate_status(@acr, true)
          @result.smart_seal[:main][:site_seal_status] = site_seal_status(ss) unless ss && ss.blank?

          @result.smart_seal[:site_seal_id] = ss.id unless ss && ss.blank?
          @result.smart_seal[:is_ev] = @acr.certificate.is_ev?
          @result.smart_seal[:is_dv] = @acr.certificate.is_dv?
          @result.smart_seal[:expired] = @acr.certificate_content.expired?
          @result.smart_seal[:valid_his_blank] = @acr.validation.validation_histories.blank?
          @result.smart_seal[:preferred_artifacts_status] = ss.preferred_artifacts_status unless ss && ss.blank?
          @result.smart_seal[:preferred_seal_image] = ss.preferred_seal_image? unless ss && ss.blank?
          @result.smart_seal[:workflow_state] = ss.workflow_state unless ss && ss.blank?
          @result.smart_seal[:is_disabled] = ss.is_disabled? unless ss && ss.blank?

          co = ss.latest_certificate_order #TODO: different with @ACR?
          r = co.certificate_content.registrant

          @result.smart_seal[:co_subject] = @acr.subject
          @result.smart_seal[:secured_site_report_subject] = co.display_subject
          @result.smart_seal[:has_artifacts] = ss.has_artifacts? unless ss && ss.blank?
          @result.smart_seal[:ss_ref] = ss.ref unless ss && ss.blank?
          @result.smart_seal[:report_certificate_status] = certificate_status(@acr)

          if r
            @result.smart_seal[:registrant_company_name] = r.company_name
            @result.smart_seal[:registrant_city_state_country] = [r.city, r.state, r.country].join(', ')
          end

          @result.smart_seal[:community_name] = Settings.community_name
          @result.smart_seal[:cc_validated] = @acr.certificate_content.validated?
          @result.smart_seal[:cc_issued] = @acr.certificate_content.issued?
          @result.smart_seal[:sc_dv] = @acr.csr.signed_certificate.is_dv?

          @result.smart_seal[:validation_histories] = []
          validation_histories = @acr.validation_histories
          validation_histories.each do |validation|
            tmp = {}
            tmp[:id] = validation.id
            tmp[:thumb] = getDocumentsPath(validation, validation.document_url(:thumb)) if validation.document_content_type =~ %r(image)
            tmp[:preview] = getDocumentsPath(validation, validation.document_url(:preview)) if validation.document_content_type =~ %r(image)
            tmp[:doc_url] = getDocumentsPath(validation, validation.document_url)
            tmp[:file_name] = validation.document_file_name.shorten(25, false)
            tmp[:file_size] = bytesToSize(Integer(validation.document_file_size))
            tmp[:created_at] = validation.created_at.strftime("%b %d, %Y")
            tmp[:updated_at] = validation.updated_at.strftime("%b %d, %Y")
            tmp[:publish_to_site_seal] = validation.publish_to_site_seal
            tmp[:viewing_method] = validation.preferred_viewing_method
            tmp[:publish_to_site_seal_approval] = validation.publish_to_site_seal_approval
            tmp[:satisfies_validation_methods] = validation.satisfies_validation_methods.join(', ') unless validation.satisfies_validation_methods.blank?

            tmp[:validation_rules] = []
            valid_rules = validation.validation_rules
            valid_rules.each do |vr|
              tmp[:validation_rules] << vr.description
            end

            @result.smart_seal[:validation_histories] << tmp
          end
          # TODO: Other_party_request(CO)
          @result.smart_seal[:other_party_request] = false
          @result.smart_seal[:valid_his_preview] = false
        end

        render(:template => @template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
    end
  rescue => e
    render_500_error e
  end

  def update_site_seal_v1_4
    @template = "api_certificate_requests/site_seal_tab_v1_4.rabl"

    if @result.save
      @acr = @result.find_certificate_order

      if params[:artifacts_status]
        @acr.site_seal.update_attributes(params[:artifacts_status])
        @result.artifacts_status = @acr.site_seal.preferred_artifacts_status
      end

      if params[:publish_to_site_seal]
        validation_his = ValidationHistory.find(params[:id])
        validation_his.update_attributes(params[:publish_to_site_seal])
        @result.id = params[:id]
        @result.publish_to_site_seal = validation_his.publish_to_site_seal
      end

      if params[:viewing_method]
        validation_his = ValidationHistory.find(params[:id])
        validation_his.update_attributes(params[:viewing_method])
        @result.id = params[:id]
        @result.viewing_method = validation_his.preferred_viewing_method
      end

      if params[:publish_to_site_seal_approval]
        validation_his = ValidationHistory.find(params[:id])
        validation_his.update_attribute(:publish_to_site_seal_approval,
                                        params[:publish_to_site_seal_approval])
        @result.id = params[:id]
        @result.publish_to_site_seal_approval = validation_his.publish_to_site_seal_approval
      end

    else
      InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
    end
    render_200_status
  rescue => e
    render_500_error e
  end

  def download_v1_4
    send_file "#{Rails.root}/tmp/certificate/#{params[:file_name]}"
  end

  def show_v1_4
    set_template "show_v1_4"
    if @result.valid?
      @acr = @result.find_certificate_order

      # Reading cache of Certificate order for "SSL-Certificate-Collection" API.
      cache = Rails.cache.read('api-retrieve-ssl-cert-' + params[:ref])
      is_new = false

      if cache.blank?
        is_new = true
      elsif JSON.parse(cache)['private_cache_key'] != @acr.certificate_content.updated_at.strftime('%Y%m%d%H%M%S')
        is_new = true
        Rails.cache.delete('api-retrieve-ssl-cert-' + params[:ref])
      end

      if is_new
        if @acr.is_a?(CertificateOrder) && @acr.errors.empty?
          package_certificate_order(@result, @acr)

          # Caching Certificate order for "Retrieve an SSL Certificate" API.
          @result.private_cache_key = @acr.certificate_content.updated_at.strftime('%Y%m%d%H%M%S')

          ApplicationRecord.include_root_in_json = false
          cache_key = 'api-retrieve-ssl-cert-' + params[:ref]

          Rails.cache.write(cache_key, @result.to_json(:methods => [
              :description, :product, :product_name, :order_status, :order_date, :registrant, :certificates,
              :common_name, :domains_qty_purchased, :wildcard_qty_purchased, :subject_alternative_names, :validations,
              :effective_date, :expiration_date, :algorithm, :external_order_number, :domains, :site_seal_code,
              :subscriber_agreement, :server_software, :contacts, :private_cache_key
          ]))
        end
      else
        @result = ApiCertificateRetrieve.new(JSON.parse(cache))
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
    end
    render_200_status
  rescue => e
    render_500_error e
  end

  def view_upload_v1_4
    @template = "api_certificate_requests/view_upload_v1_4"

    if @result.save
      @acr = @result.find_certificate_order

      if @acr.is_a?(CertificateOrder) && @acr.errors.empty?
        @result.ref = @acr.ref
        @result.subject = @acr.subject
        @result.checkout_in_progress = @acr.validation_stage_checkout_in_progress?
        @result.other_party_request = false
        @result.community_name = Settings.community_name
        @result.is_dv = @acr.certificate.is_dv?
        @result.is_dv_or_basic = @acr.certificate.is_dv_or_basic?
        @result.is_ev = @acr.certificate.is_ev?
        @result.all_domains = @acr.all_domains.join(', ')
        @result.acceptable_file_types = ValidationHistory.acceptable_file_types
        @result.validation_rules = @acr.validation.validation_rules.sort{|a,b|a.id<=>b.id}

        render(:template => @template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
    end
  rescue => e
    render_500_error e
  end

  def upload_v1_4
    @template = "api_certificate_requests/upload_v1_4"

    if @result.save
      @acr = @result.find_certificate_order

      if @acr.is_a?(CertificateOrder) && @acr.errors.empty?
        count = 0
        error = []
        message = ""
        @files = params[:fileUpload] || []

        @files.each do |file|
          if file.respond_to?(:original_filename) && file.original_filename.include?("zip")
            FileUtils.mkdir_p "#{Rails.root}/tmp/zip/temp" if !File.exist?("#{Rails.root}/tmp/zip/temp")

            if file.size > Settings.max_content_size.to_i.megabytes
              break error = <<-EOS
            Too Large: zip file #{file.original_filename} is larger than
            #{help.number_to_human_size(Settings.max_content_size.to_i.megabytes)}
              EOS
            end

            @zip_file_name=file.original_filename
            File.open("#{Rails.root}/tmp/zip/#{file.original_filename}", "wb") do |f|
              f.write(file.read)
            end

            zf = Zip::ZipFile.open("#{Rails.root}/tmp/zip/#{file.original_filename}")
            if zf.size > Settings.max_num_releases.to_i
              break error = <<-EOS
            Too Many Files: zip file #{file.original_filename} contains more than
            #{Settings.max_num_releases.to_i} files.
              EOS
            end

            zf.each do |entry|
              begin
                fpath = File.join("#{Rails.root}/tmp/zip/temp/",entry.name.downcase)

                if(File.exists?(fpath))
                  File.delete(fpath)
                end

                zf.extract(entry, fpath)
                @created_releases << create_with_attachment(LocalFile.new(fpath))

                count += 1
              rescue Errno::ENOENT, Errno::EISDIR
                error = "Invalid contents: zip entries with directories not allowed"
                break
              ensure
                if (File.exists?(fpath))
                  if File.directory?(fpath)
                    FileUtils.remove_dir fpath, :force=>true
                  else
                    FileUtils.remove_file fpath, :force=>true
                  end
                end

                @created_releases.each {|release| release.destroy} unless error.blank?
              end
            end
            File.delete(zf.name) if (File.exists?(zf.name))
            @created_releases.each do |doc|
              doc.errors.each{|attr, msg|
                error << "#{attr} #{msg}: " }
            end
          else
            vh = create_with_attachment(LocalFile.new(file.path, file.original_filename), @acr)
            vh.errors.each{|attr, msg|
              error << "#{attr} #{msg}: " }
            count += 1 if vh
            error << "Error: Document for #{file.original_filename} was not
          created. Please notify system admin at #{Settings.support_email}" unless vh
          end
        end

        if error.blank?
          unless @files.blank?

            files_were = (count > 1 or count == 0)? "documents were" : "document was"
            @result.success_message = "#{i.in_words.capitalize} (#{i}) #{files_were}
            successfully saved."

            @acr.confirmation_recipients.map{|r|r.split(" ")}.flatten.uniq.each do |c|
              OrderNotifier.validation_documents_uploaded(c, @acr, @files).deliver
            end

            OrderNotifier.validation_documents_uploaded(Settings.notify_address, @acr, @files).deliver
            OrderNotifier.validation_documents_uploaded_comodo("evdocs@comodo.com", @acr, @files).
                deliver if (@acr.certificate.is_ev? && @acr.ca_name=="comodo")
          end
        end
        @result.errors = error

        render(:template => @template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
    end
  rescue => e
    render_500_error e
  end

  def api_parameters_v1_4
    set_template "api_parameters_v1_4"

    if @result.save
      @acr = @result.find_certificate_order

      if @acr.is_a?(CertificateOrder) && @acr.errors.empty?
        # Reading cache of Api Parameters for "Retrieve acceptable domain validation methods for Certificate" API.
        cache = Rails.cache.read('api-retrieve-domain-valid-methods-' + @acr.ref + '-' + @result.api_call)

        if cache.blank?
          api_domain = "https://" + (@acr.is_test ? Settings.test_api_domain : Settings.api_domain)
          @result.parameters = @acr.to_api_string(action: @result.api_call, domain_override: api_domain, caller: "api")

          # Caching Api Parameters for "Retrieve acceptable domain validation methods for Certificate" API.
          Rails.cache.write('api-retrieve-domain-valid-methods-' + @acr.ref + '-' + @result.api_call, @result.parameters.to_json)
        else
          @result.parameters = JSON.parse(cache)
        end

        render(:template => @template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
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
    set_template "index_v1_4"
    @result.end = DateTime.now if @result.end.blank?
    client_app  = params[:client_app]

    if @result.save
      @orders = @result.find_certificate_orders(params[:search],is_sandbox_or_test? ? {is_test: true} : nil)

      page     = params[:page] || 1
      per_page = params[:per_page] || PER_PAGE_DEFAULT
      @acrs    = paginate @orders, per_page: per_page.to_i, page: page.to_i

      if @acrs.is_a?(ActiveRecord::Relation)
        @results = []
        @acrs.each do |acr|
          c = acr.certificate
          sc = acr.signed_certificate
          cc = acr.certificate_content
          is_new = false

          # Reading cache of Individual Certificate order for "SSL-Certificate-Collection" API.
          cache = Rails.cache.read('api-ssl-cert-collection-' + acr.ref + '-' + (client_app ? 'T' : 'F'))

          if cache.blank?
            is_new = true
          elsif JSON.parse(cache)['private_cache_key'] != cc.updated_at.strftime('%Y%m%d%H%M%S')
            is_new = true
            Rails.cache.delete('api-ssl-cert-collection-' + acr.ref)
          end

          if is_new
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
              result.validations = result.validations_from_comodo(acr)  if acr.external_order_number #'validations' kept executing twice so it was renamed to 'validations_from_comodo'

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
              end
            end

            # Caching Individual Certificate order for "SSL-Certificate-Collection" API.
            result.private_cache_key = cc.updated_at.strftime('%Y%m%d%H%M%S')

            ApplicationRecord.include_root_in_json = false
            cache_key = 'api-ssl-cert-collection-' + acr.ref + '-' + (client_app ? 'T' : 'F')

            Rails.cache.write(cache_key, result.to_json(:methods => [
                :ref, :description, :order_status, :order_date, :registrant, :certificates, :common_name, :domains_qty_purchased,
                :wildcard_qty_purchased, :subject_alternative_names, :validations, :effective_date, :expiration_date, :algorithm,
                :domains, :site_seal_code, :product_type, :period, :private_cache_key]))
          else
            result = ApiCertificateRetrieve.new(JSON.parse(cache))
          end

          @results << result
        end
      end

      if client_app
        render json: serialize_models(@results, meta: {orders_count: @orders.count, page: page, per_page: per_page})
      else
        @default_fields = [
          'ref',
          'description',
          'order_status',
          'order_date',
          'registrant',
          'certificates',
          'common_name',
          'domains_qty_purchased',
          'wildcard_qty_purchased',
          'subject_alternative_names',
          'validations',
          'effective_date',
          'expiration_date',
          'algorithm',
          'domains',
          'site_seal_code',
          'external_order_number'
        ]

        @fields = []
        if params[:fields] && !params[:fields].empty?
          params[:fields].split(',').each do |field|
            @fields << field
          end
        else
          @fields = @default_fields
        end

        render(template: @template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
    end
  rescue => e
    render_500_error e
  end

  def retrieve_v1_3
    if @result.save && @certificate_order.is_a?(CertificateOrder)
      set_template "success_retrieve_v1_3"
      @result.order_status = @certificate_order.status
      @result.update_attribute :response, render_to_string(:template => @template)
      render(:template => @template) and return
    else
      InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
    end
    render action: :create_v1_3
  end

  def dcv_emails_v1_3
    set_template "dcv_emails_v1_3"

    if @result.save
      @result.email_addresses={}

      if @result.domain
        # Reading cache of email address for "Acceptable Email addresses for domain control validation" API.
        cache = Rails.cache.read('api-email-addresses-' + @result.domain)

        if cache.blank?
          @result.email_addresses = ComodoApi.domain_control_email_choices(@result.domain).email_address_choices

          # Caching Certificate order for "Retrieve an SSL Certificate" API.
          cache_key = 'api-email-addresses-' + @result.domain
          Rails.cache.write(cache_key, @result.email_addresses.join('-'))
        else
          @result.email_addresses = cache.split('-')
        end
      else
        @result.domains.each do |domain|
          # Reading cache of email address for "Acceptable Email addresses for domain control validation" API.
          cache = Rails.cache.read('api-email-addresses-' + domain)

          if cache.blank?
            @result.email_addresses.merge! domain => CertificateName.candidate_email_addresses(domain)

            # Caching Certificate order for "Retrieve an SSL Certificate" API.
            cache_key = 'api-email-addresses-' + domain
            Rails.cache.write(cache_key, @result.email_addresses[domain].join('-'))
          else
            @result.email_addresses.merge! domain => cache.split('-')
          end
        end
      end

      unless @result.email_addresses.blank?
        render(:template => @template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
    end
  end

  def pretest_v1_4
    set_template "pretest_v1_4"
    if @result.save && find_certificate_order.is_a?(CertificateOrder)
      http_to_s = false # dcv_verify(params[:protocol])
      @result.is_passed = http_to_s

      render_200_status
    end
  rescue => e
    render_500_error e
  end

  def dcv_methods_v1_4
    set_template "dcv_methods_v1_4"
    if @result.save  #save the api request
      @acr = @result.find_certificate_order
      @result.dcv_methods={}
      if @acr.all_domains
        @result.instructions = ApiDcvMethods::INSTRUCTIONS
        unless @acr.csr.blank?
          @result.md5_hash = @acr.csr.md5_hash
          @result.sha2_hash = @acr.csr.sha2_hash
          @result.dns_md5_hash = @acr.csr.dns_md5_hash
          @result.dns_sha2_hash = @acr.csr.dns_sha2_hash
          @result.ca_tag = @acr.csr.ca_tag
        end
        @acr.all_domains.each do |domain|
          @result.dcv_methods.merge! domain=>{}
          @result.dcv_methods[domain].merge! "email_addresses"=> @acr.certificate_content.ca_id.nil? ?
                                              ComodoApi.domain_control_email_choices(domain).email_address_choices :
                                              CertificateName.candidate_email_addresses(domain)
          unless @acr.csr.blank?
            @result.dcv_methods[domain].merge! "http_csr_hash"=>
                                                   {"http"=>"#{@acr.csr.dcv_url(false,domain)}",
                                                    "allow_https"=>"true",
                                                    "contents"=>"#{@result.sha2_hash}\n#{@result.ca_tag}#{"\n#{@acr.csr.unique_value}" unless @acr.csr.unique_value.blank?}"}
            @result.dcv_methods[domain].merge! "cname_csr_hash"=>{"cname"=>"#{@result.dns_md5_hash}.#{domain}. CNAME #{@result.dns_sha2_hash}.#{@result.ca_tag}.","name"=>"#{@result.dns_md5_hash}.#{domain}","value"=>"#{@result.dns_sha2_hash}.#{@result.ca_tag}."}
          end
        end
      end
      unless @result.dcv_methods.blank?
        render(:template => @template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
    end
  rescue => e
    render_500_error e
  end

  def dcv_methods_csr_hash_v1_4
    set_template "dcv_methods_v1_4"
    if @result.save  # save the api request
      @acr = CertificateOrder.new
      @acr.certificate_contents.build.build_csr(body: @result.csr)

      if @acr.csr.errors.empty?
        @result.dcv_methods={}

        if @acr.csr.common_name
          # Reading cache of csr hashes for "Retrieve all validation methods based on hash of certificate signing request" API.
          cache = Rails.cache.read('api-csr-hash-' + @acr.csr.md5_hash)

          if cache.blank?
            @result.instructions = ApiDcvMethods::INSTRUCTIONS

            unless @acr.csr.blank?
              @result.md5_hash = @acr.csr.md5_hash
              @result.sha2_hash = @acr.csr.sha2_hash
              @result.dns_md5_hash = @acr.csr.dns_md5_hash
              @result.dns_sha2_hash = @acr.csr.dns_sha2_hash
              @result.ca_tag = @acr.csr.ca_tag
            end

            ([@acr.csr.common_name]+(@result.domains || [])).compact.map(&:downcase).uniq.each do |domain|
              @result.dcv_methods.merge! domain=>{}
              @result.dcv_methods[domain].merge! "email_addresses"=> @acr.certificate_content.ca_id.nil? ?
                                                  ComodoApi.domain_control_email_choices(domain).email_address_choices :
                                                  CertificateName.candidate_email_addresses(domain)
              unless @acr.csr.blank?
                @result.dcv_methods[domain].merge! "http_csr_hash"=>
                                                       {"http"=>"#{@acr.csr.dcv_url(false,domain)}",
                                                        "allow_https"=>"true",
                                                        "contents"=>"#{@result.sha2_hash}\n#{@result.ca_tag}#{"\n#{@acr.csr.unique_value}" unless @acr.csr.unique_value.blank?}"}
                @result.dcv_methods[domain].merge! "cname_csr_hash"=>{"cname"=>"#{@result.dns_md5_hash}.#{domain}. CNAME #{@result.dns_sha2_hash}.#{@result.ca_tag}.","name"=>"#{@result.dns_md5_hash}.#{domain}","value"=>"#{@result.dns_sha2_hash}.#{@result.ca_tag}."}
              end
            end

            # Caching CSR Hashes for "Retrieve all validation methods based on hash of certificate signing request" API.
            ApplicationRecord.include_root_in_json = false
            cache_key = 'api-csr-hash-' + @result.md5_hash
            Rails.cache.write(cache_key, @result.to_json(:methods => [
                :instructions, :md5_hash, :sha2_hash, :dns_md5_hash, :dns_sha2_hash, :dcv_methods, :ca_tag]))
          else
            @result.instructions = JSON.parse(cache)['instructions']
            @result.md5_hash = JSON.parse(cache)['md5_hash']
            @result.sha2_hash = JSON.parse(cache)['sha2_hash']
            @result.dns_md5_hash = JSON.parse(cache)['dns_md5_hash']
            @result.dns_sha2_hash = JSON.parse(cache)['dns_sha2_hash']
            @result.dcv_methods = JSON.parse(cache)['dcv_methods']
            @result.ca_tag = JSON.parse(cache)['ca_tag']
          end
        end

        unless @result.dcv_methods.blank?
          render(:template => @template) and return
        end
      else
        @result=@acr.csr  #so that rabl can report errors
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
    end
    render action: :dcv_methods_v1_4
  rescue => e
    render_500_error e
  end

  def dcv_email_resend_v1_3
    if @result.save
      @result.sent_at=Time.now
      unless @result.email_addresses.blank?
        set_template "success_dcv_email_resend_v1_3"
        render(:template => @template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
    end
    render action: :create_v1_3
  end

  def dcv_revoke_v1_3
    set_template "success_dcv_emails_v1_3"
    if @result.save
      @result.email_addresses=ComodoApi.domain_control_email_choices(@result.domain_name).email_address_choices
      unless @result.email_addresses.blank?
        render(:template => @template) and return
      end
    else
      InvalidApiCertificateRequest.create parameters: params, ca: ssl_ca_label
    end
    render action: :create_v1_3
  end

  private

  def package_certificate_order(result,acr)
    result.order_date = acr.created_at
    result.order_status = acr.status
    result.registrant = acr.certificate_content.registrant.to_api_query if (acr.certificate_content && acr.certificate_content.registrant)
    result.contacts = acr.certificate_content.certificate_contacts if (acr.certificate_content && acr.certificate_content.certificate_contacts)
    result.validations = result.validations_from_comodo(acr) if acr.external_order_number #'validations' kept executing twice so it was renamed to 'validations_from_comodo'
    result.description = acr.description
    result.product = acr.certificate.api_product_code
    result.product_name = acr.certificate.product
    result.subscriber_agreement = acr.certificate.subscriber_agreement_content if result.show_subscriber_agreement =~ /[Yy]/
    result.external_order_number = acr.ext_customer_ref
    result.server_software = acr.server_software.id if acr.server_software

    if acr.certificate.is_ucc?
      result.domains_qty_purchased = acr.purchased_domains('all').to_s
      result.wildcard_qty_purchased = acr.purchased_domains('wildcard').to_s
    else
      result.domains_qty_purchased = "1"
      result.wildcard_qty_purchased = acr.certificate.is_wildcard? ? "1" : "0"
    end

    if (acr.signed_certificate && result.query_type != "order_status_only")
      result.certificates =
          acr.signed_certificate.to_format(response_type: result.response_type, # assume comodo issued cert
                                            response_encoding: result.response_encoding) || acr.signed_certificate.to_nginx
      result.common_name = acr.signed_certificate.common_name
      result.subject_alternative_names = acr.signed_certificate.subject_alternative_names
      result.effective_date = acr.signed_certificate.effective_date
      result.expiration_date = acr.signed_certificate.expiration_date
      result.algorithm = acr.signed_certificate.is_SHA2? ? "SHA256" : "SHA1"
    elsif (acr.csr)
      result.certificates = nil
      result.common_name = acr.csr.common_name
    end
  end

  def record_parameters
    @result = klass.new(_wrap_parameters(params)['api_certificate_request'] || params[:api_certificate_request])
    @result.debug ||= params[:debug] if params[:debug]
    @result.send_to_ca ||= params[:send_to_ca] if params[:send_to_ca]
    @result.action ||= params[:action]
    @result.ref ||= params[:ref] if params[:ref]
    @result.options ||= params[:options] if params[:options]
    @result.test = @test
    @result.request_url = request.url
    @result.parameters = params.to_utf8.to_json
    @result.raw_request = request.raw_post.force_encoding("ISO-8859-1").encode("UTF-8")
    @result.request_method = request.request_method
    @result.saved_registrant ||= params[:saved_registrant] if params[:saved_registrant]
  end

  def klass
    case params[:action]
    when "create_v1_3"
      ApiCertificateCreate
    when "create_v1_4", "update_v1_4", "contacts_v1_4", "replace_v1_4"
      ApiCertificateCreate_v1_4
    when /revoke/
      ApiCertificateRevoke
    when "retrieve_v1_3", "show_v1_4", "index_v1_4", "detail_v1_4", "view_upload_v1_4", "upload_v1_4",
        "update_site_seal_v1_4", "generate_certificate_v1_4","callback_v1_4"
      ApiCertificateRetrieve
    when "certificate_enrollment_order"
      ApiCertificateEnrollment
    when "retrieve_signed_certificates"
      ApiSignedCertificateRequest
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
  end

  def find_certificate_order
    @certificate_order = @result.find_certificate_order
  end

  def csr
    @csr || @certificate_order.csr
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
      path += certificate_order.signed_certificate.nonidn_friendly_common_name + '.crt'
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

  def create_with_attachment(file, certificate_order)
    @val_history = ValidationHistory.new(:document => file)
    certificate_order.validation.validation_histories << @val_history
    @val_history.save
    @val_history
  end

  def certificate_status(co, is_managing=nil)
    pending = is_managing ? "info" : "warning"
    cc=co.certificate_content
    case cc.workflow_state
      when "issued"
        if cc.csr.signed_certificate.blank?
          ["certificate missing", "danger"]
        else
          ef, ex = [cc.csr.signed_certificate.effective_date, cc.csr.
              signed_certificate.expiration_date]
          if ex.blank? || ef.blank?
            #these were signed certs transferred over and somehow were missing these dates
            ["invalid certificate", "danger"]
          elsif ex < Time.now
            ["invalid (expired on #{ex.strftime("%b %d, %Y")})", pending]
          elsif ef > Time.now
            ["invalid (starts on #{ef.strftime("%b %d, %Y")})", pending]
          else
            ["valid (#{ef.strftime("%b %d, %Y")} - #{ex.strftime("%b %d, %Y")})",
             "success"]
          end
        end
      when "canceled"
        ["canceled", "danger"]
      when "revoked"
        ["revoked", "danger"]
      else
        ["pending issuance", pending]
    end
  end

  def site_seal_status(site_seal)
    case site_seal.workflow_state
      when "new"
        [SiteSeal::NEW_STATUS, 'danger']
      when SiteSeal::FULLY_ACTIVATED.to_s
        [SiteSeal::FULLY_ACTIVATED_STATUS, 'success']
      when SiteSeal::CONDITIONALLY_ACTIVATED.to_s
        [SiteSeal::CONDITIONALLY_ACTIVATED_STATUS, 'warning']
      when SiteSeal::DEACTIVATED.to_s
        [SiteSeal::DEACTIVATED_STATUS, 'danger']
      when SiteSeal::CANCELED.to_s
        [SiteSeal::CANCELED_STATUS, 'danger']
      else
        ['','']
    end
  end

  def bytesToSize(bytes)
    sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB']
    return '0 Byte' if (bytes == 0)

    i = (Math.log(bytes) / Math.log(1024)).floor
    return (bytes / (1024**i)).round(2).to_s + ' ' + sizes[i]
  end

  def getDocumentsPath(vh, path)
    file_name = path[(path.rindex('/') + 1)..path.length]
    param_style = file_name[0..(file_name.rindex('.') - 1)]

    style = if vh.document_file_name.force_encoding('UTF-8').include?(file_name)
              vh.document.default_style
            else
              param_style.to_sym
            end

    vh.authenticated_s3_get_url style: style
  end

  def set_template(filename)
    @template = File.join('api', 'v1', 'api_certificate_requests', filename)
  end

  def ssl_ca_label
    I18n.t('labels.ssl_ca')
  end

  def dcv_param
    params[:domains].first[1]['dcv'].presence || ''
  end

  def set_certificate_order
    @certificate_order = CertificateOrder.find_by(ref: params[:ref])
    json_render_not_found && return if @certificate_order.nil?

    @certificate_order
  end

  def verify_dcv_method
    if dcv_param.present?
      unless %w[http https email cname acme_http acme_dns_txt].include? dcv_param
        errors = { errors: [parameters: "invalid dcv_method: #{dcv_param}"] }
        render_errors(errors, :unprocessable_entity) && return
      end
    end
  end
end
