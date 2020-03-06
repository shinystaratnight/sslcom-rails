# == Schema Information
#
# Table name: ca_api_requests
#
#  id                   :integer          not null, primary key
#  api_requestable_type :string(191)
#  ca                   :string(255)
#  certificate_chain    :text(65535)
#  method               :string(255)
#  parameters           :text(65535)
#  raw_request          :text(65535)
#  request_method       :text(65535)
#  request_url          :text(65535)
#  response             :text(16777215)
#  type                 :string(191)
#  username             :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#  api_requestable_id   :integer
#  approval_id          :string(255)
#
# Indexes
#
#  index_ca_api_requests_on_api_requestable                          (api_requestable_id,api_requestable_type)
#  index_ca_api_requests_on_id_and_type                              (id,type)
#  index_ca_api_requests_on_type_and_api_requestable                 (id,api_requestable_id,api_requestable_type,type) UNIQUE
#  index_ca_api_requests_on_type_and_api_requestable_and_created_at  (id,api_requestable_id,api_requestable_type,type,created_at)
#  index_ca_api_requests_on_type_and_username                        (type,username)
#  index_ca_api_requests_on_username_and_approval_id                 (username,approval_id) UNIQUE
#

require "declarative_authorization/maintenance"

class ApiCertificateCreate_v1_4 < ApiCertificateRequest
  include CertificateType
  attr_accessor :csr_obj, # temporary csr object
    :certificate_url, :receipt_url, :smart_seal_url, :validation_url, :order_number, :order_amount, :order_status,
    :api_request, :api_response, :error_code, :error_message, :eta, :send_to_ca, :ref, :renewal_id, :saved_registrant,
    :certificates, :success_message

  DCV_FAILURE_ACTIONS = %w(remove ignore)

  PRODUCTS = Settings.api_product_codes.to_hash.stringify_keys

  DCV_METHODS = %w(email http_csr_hash cname_csr_hash https_csr_hash)
  DEFAULT_DCV_METHOD = "http_csr_hash"
  DEFAULT_DCV_METHOD_COMODO = "HTTPCSRHASH"

  validates :account_key, :secret_key, presence: true
  validates :ref, presence: true, if: lambda{|c|['update_v1_4', 'show_v1_4'].include?(c.action)}
  validates :csr, presence: true, unless: lambda{|c| c.ref.blank? || c.is_processing? || c.is_attestation_processing?}
  validates :period, presence: true, format: /\d+/,
    inclusion: {in: ApiCertificateRequest::NON_EV_SSL_PERIODS,
    message: "needs to be one of the following: #{NON_EV_SSL_PERIODS.join(', ')}"}, if: lambda{|c| (c.is_dv? || c.is_ov?) &&
          !c.is_free? && c.ref.blank? && ['create_v1_4'].include?(c.action)}
  validates :period, presence: true, format: {with: /\d+/},
    inclusion: {in: ApiCertificateRequest::EV_SSL_PERIODS,
    message: "needs to be one of the following: #{EV_SSL_PERIODS.join(', ')}"}, if: lambda{|c|c.is_ev? && c.ref.blank? &&
    ['create_v1_4'].include?(c.action)}
  validates :period, presence: true, format: {with: /\d+/},
    inclusion: {in: ApiCertificateRequest::EV_CS_PERIODS,
    message: "needs to be one of the following: #{EV_CS_PERIODS.join(', ')}"}, if: lambda{|c|c.is_evcs? && c.ref.blank? &&
    ['create_v1_4'].include?(c.action)}
  validates :period, presence: true, format: {with: /\d+/},
    inclusion: {in: ApiCertificateRequest::FREE_PERIODS,
    message: "needs to be one of the following: #{FREE_PERIODS.join(', ')}"}, if: lambda{|c|c.is_free? && c.ref.blank? &&
    ['create_v1_4'].include?(c.action)}
  validates :product, presence: true, format: {with: /\d{3}/},
      inclusion: {in: PRODUCTS.keys.map(&:to_s),
      message: "needs to one of the following: #{PRODUCTS.keys.map(&:to_s).join(', ')}"}, if:
      lambda{|c|['create_v1_4'].include?(c.action)}
  validates :server_software, presence: true, format: {with: /\d+/}, inclusion:
      {in: ServerSoftware.pluck(:id).map(&:to_s),
      message: "needs to be one of the following: #{ServerSoftware.pluck(:id).map(&:to_s).join(', ')}"},
            if: lambda{|c|c.is_server? && c.csr && Settings.require_server_software_w_csr_submit}
  validates :organization, presence: true, if: lambda{|c|c.csr && (!c.is_dv? && c.csr_obj.organization.blank?)}
  validates :post_office_box, presence: {message: "is required if street_address_1 is not specified"},
            if: lambda{|c|!c.is_dv? && c.street_address_1.blank? && c.csr} #|| c.parsed_field("POST_OFFICE_BOX").blank?}
  validates :street_address_1, presence: {message: "is required if post_office_box is not specified"},
            if: lambda{|c|!c.is_dv? && c.post_office_box.blank? &&c.csr} #|| c.parsed_field("STREET1").blank?}
  validates :locality_name, presence: true, if: lambda{|c|c.csr && (!c.is_dv? && c.csr_obj.locality.blank?)}
  validates :state_or_province_name, presence: true, if: lambda{|c|csr && (!c.is_dv? && c.csr_obj.state.blank?)}
  validates :postal_code, presence: true, if: lambda{|c|c.csr && !c.is_dv?} #|| c.parsed_field("POSTAL_CODE").blank?}
  validates :country, presence: true, inclusion:
      {in: Country.accepted_countries, message: "needs to be one of the following: #{Country.accepted_countries.join(', ')}"},
      if: lambda{|c| c.csr && c.csr_obj && c.csr_obj.country.try("blank?")}
  #validates :registered_country_name, :incorporation_date, if: lambda{|c|c.is_ev?}
  validates :dcv_method, inclusion: {in: ApiCertificateCreate::DCV_METHODS,
      message: "needs to one of the following: #{DCV_METHODS.join(', ')}"}, if: lambda{|c|c.dcv_method}
  validates :contact_email_address, email: true, unless: lambda{|c|c.contact_email_address.blank?}
  validates :business_category, format: {with: /[bcd]/}, unless: lambda{|c|c.business_category.blank?}
  validates :common_names_flag, format: {with: /[01]/}, unless: lambda{|c|c.common_names_flag.blank?}
  validates :unique_value, format: {with: /[a-zA-Z0-9]{1,20}/}, unless: lambda{|c|c.unique_value.blank?}
  # use code instead of serial allows attribute changes without affecting the cert name
  validate :verify_dcv, on: :create, if: "!domains.blank?"

  ########### Note to development team: Evaluate the utility of validate_contacts ##########################
  # validate :validate_contacts, unless: lambda{|c|c.contacts.blank?}
  ##########################################################################################################

  validate :validate_callback, unless: lambda{|c|c.callback.blank?}
  validate :renewal_exists, if: lambda{|c|c.renewal_id}

  before_validation do
    retrieve_registrant
    self.period = period.to_s unless period.blank?
    self.product = product.to_s unless product.blank?
    if new_record?
      if self.csr # a single domain validation
        self.server_software ||= ServerSoftware::OTHER
        self.dcv_method ||= "http_csr_hash"
        self.csr_obj = Csr.new(body: self.csr) # this is only for validation and does not save
        self.csr_obj.csr_unique_values.build(unique_value: unique_value) unless unique_value.blank?
        unless self.csr_obj.errors.empty?
          self.errors[:csr] << "has problems and or errors"
        end
      elsif self.api_requestable.is_a?(CertificateName) # a multi domain validation
        #TODO add dcv validation
      end

      if is_attestation_processing?
        unless AttestationCertificate.attestation_pass?(attestation_certificate, attestation_issuer_certificate)
          self.errors[:attestation] << "attestation failed"
        end
      end
    end
    # verify_domain_limits
  end

  def resend_domain_validation
    @certificate_order = self.find_certificate_order

    # Checking the certificatea order's current status
    if @certificate_order.certificate_content.pending_validation?
      cert_names = {}
      domains = {}

      # Preparing parameters for domain validation
      if @certificate_order.certificate_content.ca_id.blank?
        mdc_validation = ComodoApi.mdc_status(@certificate_order)
        ds = mdc_validation.domain_status

        if ds
          names = @certificate_order.certificate_content.certificate_names.find_by_domains(ds.keys)
          names.each do |cn|
            if !ds[cn.name]['status'].blank? &&
                ds[cn.name]['status'].casecmp('validated') != 0 &&
                !ds[cn.name]['method'].blank?
              cert_names[cn.name] = cn.name
              domains[cn.name] = {}
              domains[cn.name]['dcv'] = ds[cn.name]['method']
              domains[cn.name]['dcv_failure_action'] = 'ignore'
            end
          end
        end
      else
        @certificate_order.certificate_content.certificate_names.includes(:domain_control_validations).each do |cn|
          dcv = cn.domain_control_validations.last

          if dcv && !dcv.satisfied?
            cert_names[cn.name] = cn.name
            domains[cn.name] = {}
            domains[cn.name]['dcv'] = dcv.email_address ? dcv.email_address : dcv.dcv_method
            domains[cn.name]['dcv_failure_action'] = 'ignore'
          end
        end
      end

      # Checking the current certificate order's validate history
      if cert_names.size > 0
        @cert_names = cert_names
        @domains = domains
        @acr = self.update_certificate_order

        # Domain Contorl Valdation verification for non-email method.
        unless @certificate_order.certificate_content.ca_id.blank?
          @certificate_order.certificate_content.certificate_names.includes(:domain_control_validations).each do |cn|
            dcv = cn.domain_control_validations.last
            dcv.satisfy!  if dcv && !dcv.satisfied? && dcv.dcv_method != 'email' && cn.dcv_verify(dcv.dcv_method)
          end
        end

        return @acr
      end

      return "empty_dcv"
    else
      return "incorrect_state"
    end
  end

  def create_certificate_order
    certificate = Certificate.for_sale.find_by_serial(PRODUCTS[self.product.to_s]+api_requestable.tier_suffix)
    co_params = {duration: period, is_test: self.test, ext_customer_ref: external_order_number}
    co = api_requestable.certificate_orders.build(co_params)
    if self.csr
      # process csr
      csr = self.csr_obj
      csr.save
    else
      # or make a certificate voucher
      co.preferred_payment_order = 'prepaid'
    end
    certificate_content=CertificateContent.new(
        csr: csr, server_software_id: self.server_software, domains: get_domains,
        ca: certificate.cas.ssl_account_or_general_default(api_requestable).last)
    co.certificate_contents << certificate_content
    @certificate_order = Order.setup_certificate_order(
      certificate: certificate,
      certificate_order: co,
      duration: self.period.to_i/365
    )
    order = api_requestable.purchase(@certificate_order)
    order.cents = @certificate_order.attributes_before_type_cast["amount"].to_f

    if errors.blank?
      if certificate_content.valid?
        apply_funds(
          certificate_order: @certificate_order,
          ssl_account:       api_requestable,
          order:             order
        )
        return self unless errors.blank?
        order.save

        if certificate_content.save
          setup_certificate_content(
              certificate_order: @certificate_order,
              certificate_content: certificate_content,
              ssl_account: api_requestable,
              contacts: self.contacts,
              certificate: certificate)

          if is_attestation_processing?
            create_attestation_certificate(
                attestation_certificate.strip,
                certificate_content,
                AttestationCertificate
            )
            create_attestation_certificate(
                attestation_issuer_certificate.strip,
                certificate_content,
                AttestationIssuerCertificate
            )
          end
        end

        # if csr && certificate_content.save
        #   setup_certificate_content(
        #       certificate_order: @certificate_order,
        #       certificate_content: certificate_content,
        #       ssl_account: api_requestable,
        #       contacts: self.contacts)
        # end

        certificate_content.url_callbacks.create(callback) if callback
        return @certificate_order
      else
        return certificate_content
      end
    end
    self
  end

  def replace_certificate_order
    @certificate_order = self.find_certificate_order
    self.domains = {self.csr_obj.common_name=>{"dcv"=>"http_csr_hash"}} if self.domains.blank?
    # caa_check_domains = parameters_to_hash["caa_check_domains"].split(',')
    caa_check_domains = self.caa_check_domains.split(',') unless self.caa_check_domains.blank?

    if @certificate_order.is_a?(CertificateOrder)
      # CAA Checking for domains what has been validated and no passed for CAA.
      unless caa_check_domains.blank?
        @certificate_order.certificate_content.certificate_names.find_by_domains(caa_check_domains).each do |cn|
          CaaCheck.pass?(@certificate_order.ref, cn, cn.certificate_content)
        end
      end

      @certificate_order.update_attribute(:external_order_number, self.ca_order_number) if (self.admin_submitted && self.ca_order_number)
      @certificate_order.update_attribute(:ext_customer_ref, self.external_order_number) if self.external_order_number
      @certificate_order.is_test = self.test

      if @certificate_order.certificate_content && @certificate_order.certificate_content.pending_validation? &&
          (@certificate_order.external_order_number || !@certificate_order.certificate_content.ca.blank?)
        cn_keys = self.cert_names.keys

        @certificate_order.certificate_content.certificate_names.includes{:domain_control_validations}.
            each do |certificate_name|
          # if cn_keys.include? certificate_name.id.to_s
          #   certificate_name.update_column(:name, self.cert_names[certificate_name.id.to_s])
          # else
          #   certificate_name.destroy
          # end

          if cn_keys.exclude? certificate_name.name
            unless @certificate_order.certificate_content.ca_id.nil?
              dcvs = certificate_name.domain_control_validations
              dcvs.destroy_all if dcvs.size > 0
            end

            certificate_name.destroy

            # Remove Domain from Notification Group
            NotificationGroup.auto_manage_cert_name(@certificate_order.certificate_content, 'delete', certificate_name)
          elsif self.cert_names[certificate_name.name] != certificate_name.name
            dcv = certificate_name.domain_control_validations.last
            if !dcv || (dcv && !dcv.satisfied?)
              certificate_name.update_column(:name, self.cert_names[certificate_name.name])
              NotificationGroup.auto_manage_cert_name(@certificate_order.certificate_content, 'update', certificate_name)
            elsif dcv && dcv.satisfied?
              self.cert_names[certificate_name.name] = certificate_name.name
            end
          end
        end
        cn_vals = self.cert_names.map{|k, v|v}

        # @certificate_order.certificate_content.update_attribute(:domains, self.domains.keys)
        @certificate_order.certificate_content.update_attribute(:domains, cn_vals)
        @certificate_order.certificate_content.dcv_domains({domains: self.domains, emails: self.dcv_candidate_addresses})

        # domainNames = self.domains.keys.join(',')
        # domainDcvs = self.domains.keys.map{|k|"#{@certificate_order.certificate_content.certificate_names.find_by_name(k).try(:last_dcv_for_comodo)}"}.join(',')

        #send to comodo
        if @certificate_order.certificate_content.ca_id.nil?
          comodo_auto_replace_ssl(
              certificate_order: @certificate_order,
              domainNames: cn_vals.join(',')
          # domainDcvs: domainDcvs
          )
        end
      end

      return @certificate_order
    end
    self
  end

  def update_certificate_order
    @certificate_order = self.find_certificate_order
    self.domains = {self.csr_obj.common_name=>{"dcv"=>"http_csr_hash"}} if self.domains.blank?
    caa_check_domains = self.caa_check_domains.split(',') unless self.caa_check_domains.blank?

    if @certificate_order.is_a?(CertificateOrder)
      # CAA Checking for domains what has been validated and no passed for CAA.
      unless caa_check_domains.blank?
        @certificate_order.certificate_content.certificate_names.find_by_domains(caa_check_domains).each do |cn|
          CaaCheck.pass?(@certificate_order.ref, cn, cn.certificate_content)
        end
      end

      @certificate_order.update_attribute(:external_order_number, self.ca_order_number) if # from API
          (self.admin_submitted && self.ca_order_number)
      @certificate_order.update_attribute(:ext_customer_ref, self.external_order_number) if self.external_order_number
      # choose the right ca_certificate_id for submit to Comodo
      @certificate_order.is_test = self.test

      #assume updating domain validation, already sent to comodo
      if @certificate_order.certificate_content && @certificate_order.certificate_content.pending_validation? &&
          (@certificate_order.external_order_number || !@certificate_order.certificate_content.ca.blank?)
        @certificate_order.certificate_content.update_attribute(:domains, self.domains.keys)
        @certificate_order.certificate_content.dcv_domains({domains: self.domains, emails: self.dcv_candidate_addresses})

        #send to comodo if ca_id is nil
        if @certificate_order.certificate_content.ca_id.nil?
          comodo_auto_update_dcv(certificate_order: @certificate_order)
        end
      # elsif is_attestation_processing?
      #   unless self.attestation_pass? && @certificate_order.certificate_content.validated!
      #     cert_body = SignedCertificate.enclose_with_tags(attestation_certificate.strip)
      #     parsed = OpenSSL::X509::Certificate.new(cert_body)
      #
      #     api_log_entry = SslcomCaApi.apply_for_attestation(@certificate_order, parsed, nil)
      #     if api_log_entry.message.blank? && !api_log_entry.username.blank?
      #       SslcomCaApi.apply_for_attestation(@certificate_order, parsed, api_log_entry.username)
      #     end
      #   end
      else
        if self.csr_obj # was a csr submitted?
          certificate_content = @certificate_order.certificate_contents.build
          csr = self.csr_obj
          csr.save
          certificate_content.csr = csr
          certificate_content.server_software_id = server_software
          certificate_content.domains = domains.keys unless domains.blank?
          certificate_content.submit_csr!
          if errors.blank?
            if certificate_content.save
              setup_certificate_content(
                  certificate_order: @certificate_order,
                  certificate_content: certificate_content,
                  contacts: self.contacts)
              certificate_content.url_callbacks.create(callback) if callback
            else
              return certificate_content
            end
          end
        else
          certificate_content = @certificate_order.certificate_content
          certificate_content.domains = domains.keys unless domains.blank?
          send_dcv(certificate_content)
        end
      end

      return @certificate_order
    end

    self
  end

  def certificate_order_callback
    @certificate_order=self.find_certificate_order
    if @certificate_order.is_a?(CertificateOrder)
      self.callback_hook = @certificate_order.certificate_content.callback(self.callback)
    end
    self
  end

  def update_certificate_content_contacts
    @certificate_order=self.find_certificate_order
    if @certificate_order.is_a?(CertificateOrder)
      contacts = self.contacts
        c = @certificate_order.certificate_content.certificate_contacts
        c.each do |contact|
          role = contact.roles[0]
          if role
            contact.update_attributes(contacts[role])
          end
          unless contact.valid?
            errors[:contacts] << {role.to_sym => c[role].errors}
          end
        end
    end
    self
  end

  def comodo_auto_replace_ssl(options={send_to_ca: true})
    res = ComodoApi.auto_replace_ssl(options)
    comodo_auto_update_dcv(options) if res[0] == '0'
  end

  # this update dcv method to comodo for each domain
  def comodo_auto_update_dcv(options={send_to_ca: true})
    names = options[:certificate_order].certificate_content.certificate_names.find_by_domains(self.domains.keys)
    names.map do |name|
      # ComodoApi.delay.auto_update_dcv(dcv:
      ComodoApi.auto_update_dcv(dcv:
        name.domain_control_validations.last, send_to_ca: options[:send_to_ca])
    end
  end

  DomainJob = Struct.new(:cc, :acc, :dcv_failure_action, :domains, :dcv_candidate_addresses) do
    def perform
      cc.dcv_domains({domains: (domains || [cc.csr.common_name]), emails: dcv_candidate_addresses,
                            dcv_failure_action: dcv_failure_action})
      cc.pend_validation!(ca_certificate_id: acc[:ca_certificate_id],
                          send_to_ca: acc[:send_to_ca] || true) unless cc.pending_validation?
    end
  end

  def setup_certificate_content(options)
    cc = options[:certificate_content]
    cc.registrant.destroy unless cc.registrant.blank?
    cc.add_ca(options[:certificate_order].ssl_account) if options[:certificate_order].external_order_number.blank?
    cc.create_registrant(
        company_name: (self.organization.force_encoding("ISO-8859-1").encode("UTF-8") unless
            self.organization.nil?),
        department: (self.organization_unit.force_encoding("ISO-8859-1").encode("UTF-8") unless
            self.organization_unit.nil?),
        po_box: (self.post_office_box.force_encoding("ISO-8859-1").encode("UTF-8") unless self.post_office_box.nil?),
        address1: (self.street_address_1.force_encoding("ISO-8859-1").encode("UTF-8") unless
            self.street_address_1.nil?),
        address2: (self.street_address_2.force_encoding("ISO-8859-1").encode("UTF-8") unless
            self.street_address_2.nil?),
        address3: (self.street_address_3.force_encoding("ISO-8859-1").encode("UTF-8") unless
            self.street_address_3.nil?),
        city: (self.locality_name.force_encoding("ISO-8859-1").encode("UTF-8") unless self.locality_name.nil?),
        state: (self.state_or_province_name.force_encoding("ISO-8859-1").encode("UTF-8") unless
            self.state_or_province_name.nil?),
        postal_code: (self.postal_code.force_encoding("ISO-8859-1").encode("UTF-8") unless self.postal_code.nil?),
        country: self.country || csr_obj.try(:country))
    if self.try(:recipient)
      recipient_attr = JSON.parse self.recipient
      assignee = options[:certificate_order].assignee || User.find_or_initialize_by(email: recipient_attr["email"])
      assignee.login ||= recipient_attr["email"]
      assignee.save
      recipient_attr[:user_id] = assignee.id
      options[:certificate_order].create_locked_recipient(recipient_attr)
    end
    ######ASK leo about this ########
    if (options[:certificate].present? && !options[:certificate].is_server?) || cc.csr_submitted?
      cc.provide_info!
      if Contact.optional_contacts? && contacts && contacts[:saved_contacts]
        sc = contacts[:saved_contacts]
        if sc && sc.is_a?(Array) && sc.any?
          sc.each do |c_id|
            c = CertificateContact.new(
              retrieve_saved_contact({saved_contact: c_id}, ['roles']).merge(parent_id: c_id)
            )
            if c.valid?
              cc.certificate_contacts << c
            else
              errors[:contacts] << {
                "saved_contact_#{c_id}" => "Failed to create contact: #{c.errors.full_messages.join(', ')}."
              }
            end
          end
        end
      else
        CertificateContent::CONTACT_ROLES.each do |role|
          c = if options[:contacts] && (options[:contacts][role] || options[:contacts][:all])
                CertificateContact.new(retrieve_saved_contact(
                    options[:contacts][(options[:contacts][role] ? role : :all)].to_utf8,
                    %w(company_name department)
                ))
              elsif api_requestable.reseller
                attributes = api_requestable.reseller.attributes.select do |attr, value|
                  (CertificateContact.column_names-%w(id created_at)).include?(attr.to_s)
                end
                contact = CertificateContact.new
                contact.assign_attributes(attributes, without_protection: true)
                contact
              end
          unless c.blank?
            c.clear_roles
            c.add_role! role
            unless c.valid?
              errors[:contacts] << {role.to_sym => c.errors}
            else
              cc.certificate_contacts << c
              cc.update_attribute(role+"_checkbox", true) unless
                  role==CertificateContent::ADMINISTRATIVE_ROLE
            end
          end
        end
      end
      cc.provide_contacts!
      options[:certificate_order].orphaned_certificate_contents remove: true
      if options[:certificate_order].domains_validated?
        options[:certificate_order].validate!
        api_log_entry=options[:certificate_order].apply_for_certificate(mapping: cc.ca)
        if api_log_entry
          if api_log_entry.instance_of?(SslcomCaRequest) and api_log_entry.response=~/Check CAA/
            self.order_status =
                "CAA validation failed. See https://#{Settings.portal_domain}/how-to/configure-caa-records-to-authorize-ssl-com/"
          end
          cc.issue! unless api_log_entry.certificate_chain.blank?
        end
      else
        send_dcv(cc)
      end if options[:certificate_order].certificate.is_server?
    end
  end

  def send_dcv(cc)
    if self.debug=="true" || (self.domains && self.domains.count <= Validation::COMODO_EMAIL_LOOKUP_THRESHHOLD)
      cc.dcv_domains({domains: self.domains, emails: self.dcv_candidate_addresses,
                      dcv_failure_action: self.options.blank? ? nil : self.options['dcv_failure_action']})
      cc.pend_validation!(ca_certificate_id: ca_certificate_id, send_to_ca: send_to_ca || true) unless cc.pending_validation?
    else
      job_group = Delayed::JobGroups::JobGroup.create!
      job_group.enqueue(DomainJob.new(cc, {ca_certificate_id: self.ca_certificate_id, send_to_ca: self.send_to_ca || true},
                                      self.options.blank? ? nil : self.options['dcv_failure_action'], self.domains,
                                      self.dcv_candidate_addresses))
      job_group.mark_queueing_complete
    end
  end

  def apply_funds(options)
    order = options[:order]
    if order.line_items.size > 0
      paid = if parameters_to_hash['billing_profile'].nil?
        apply_to_funded_account(options)
      else
        apply_to_billing_profile(options)
      end
      if paid
        order.mark_paid!
        options[:certificate_order].pay!(true)
      end
    end
  end

  def apply_to_funded_account(options)
    applied = false
    order = options[:order]
    funded_account = options[:ssl_account].funded_account
    if funded_account.cents < order.cents && !debug_mode?
      self.errors[:funded_account] = "Not enough funds in the account to complete this purchase! Please deposit additional #{Money.new(order.cents - funded_account.cents).format}."
    end
    if errors[:funded_account].blank?
      self.errors.delete :billing_profile
      self.errors.delete :funded_account
      funded_account.cents -= order.cents
      funded_account.deduct_order = true
      applied = true
      Authorization::Maintenance::without_access_control do
        funded_account.save unless debug_mode?
      end
    end
    applied
  end

  def apply_to_billing_profile(options)
    response = false
    last_digits = parameters_to_hash['billing_profile']
    if last_digits
      profile = options[:ssl_account].billing_profiles.find_by(last_digits: last_digits)
      if profile
        gateway_response = options[:order].purchase(
          profile.build_credit_card,
          profile.build_info(Order::SSL_CERTIFICATE)
            .merge(owner_email: options[:ssl_account].get_account_owner.email)
        )
        if gateway_response.success?
          response = true
        else
          self.errors[:billing_profile] = gateway_response.message
        end
      else
        self.errors[:billing_profile] = "Could not find billing profile ending in #{billing_profile} for this account!"
      end
    end
    response
  end

  def renewal_exists
    self.errors[:renewal_id] << "renewal_id #{self.renewal_id} does not exist or is invalid" if
        self.api_requestable.certificate_orders.find_by_ref(self.renewal_id).blank?
  end

  # must belong to a list of acceptable email addresses
  def verify_dcv
    #if submitting domains, then a csr must have been submitted on this or a previous request
    if !csr.blank? || is_processing?
      self.dcv_candidate_addresses = {}
      if self.domains.is_a?(Array)
        values = Array.new(self.domains.count,"dcv"=>"HTTP_CSR_HASH")
        self.domains = (self.domains.zip(values)).to_h
      end
      self.domains.each do |k,v|
        unless v["dcv"] =~ /https?/i || v["dcv"] =~ /cname/i
          unless v["dcv"]=~EmailValidator::EMAIL_FORMAT
            errors[:domains] << "domain control validation for #{k} failed. #{v["dcv"]} is an invalid email address."
          else
            self.dcv_candidate_addresses[k]=[]
            # self.dcv_candidate_addresses[k]=ComodoApi.domain_control_email_choices(k).email_address_choices
            # errors[:domains] << "domain control validation for #{k} failed. Invalid email address #{v["dcv"]} was submitted but only #{self.dcv_candidate_addresses[k].join(", ")} are valid choices." unless
            #     self.dcv_candidate_addresses[k].include?(v["dcv"])
          end
        end
        v["dcv_failure_action"] ||= "ignore"
      end
    elsif csr.blank?
      # allow domains without the csr so commented out below
      # errors[:domains] << "csr has not been submitted yet."
    elsif !api_requestable.certificate_content.pending_validation?
      errors[:domains] << "certificate order is not in validation stage."
    else
      errors[:domains] << "domain control validation failed. Please contact support@ssl.com for more information."
    end
  end

  ########### Note to development team: Evaluate the utility of validate_contacts ##########################
  # def validate_contacts
  #   if contacts
  #     if !contacts.is_a?(Hash)
  #         errors[:contacts] << "expecting hash"
  #       return false
  #     end
  #     errors[:contacts] = {}
  #     if Contact.optional_contacts? && contacts[:saved_contacts]
  #       sc = contacts[:saved_contacts]
  #       if sc && sc.is_a?(Array) && sc.any?
  #         found = 0
  #         sc.each {|c| found += 1 if api_requestable.all_saved_contacts.find_by(id: c.to_i)}
  #         errors[:contacts].push(saved_contacts: "Contacts with ids #{sc.join(', ')} do not exist.") unless found > 0
  #       else
  #         errors[:contacts].push(saved_contacts: "Zero contacts provided, please pass a list of saved contact ids. E.g.: [1, 5, 6].")
  #       end
  #     else
  #       CertificateContent::CONTACT_ROLES.each do |role|
  #         if (contacts[role] || contacts['all'])
  #           c_role = contacts[role] ? role : 'all'
  #           attrs  = retrieve_saved_contact(contacts[c_role], [c_role])
  #           extra  = (attrs.keys - permit_contact_fields).flatten
  #           if attrs[:saved_contact] # failed to find saved contact by id
  #             errors[:contacts].last[:role] = c_role
  #           elsif !extra.empty?
  #             msg = {c_role.to_sym => "The following parameters are invalid: #{extra.join(', ')}"}
  #             errors[:contacts].last.merge!(msg)
  #           elsif !CertificateContact.new(attrs.to_utf8.merge(roles: [role])).valid?
  #             r = CertificateContact.new(attrs.to_utf8.merge(roles: [role]))
  #             r.valid?
  #             errors[:contacts].last.merge!(c_role.to_sym => r.errors)
  #           elsif attrs['country'].blank? || Country.find_by_iso1_code(attrs['country'].upcase).blank?
  #             msg = {c_role.to_sym => "The 'country' parameter has an invalid value of '#{attrs['country']}'"}
  #             errors[:contacts].last.merge!(msg)
  #           end
  #         else
  #           msg = {role.to_sym => "contact information missing"}
  #           errors[:contacts].last.merge!(msg)
  #         end
  #       end
  #     end
  #   else
  #     errors[:contacts] << "parameter required"
  #   end
  #   cur_err = errors[:contacts].reject(&:empty?)
  #   errors.delete(:contacts)
  #   errors.add(:contacts, cur_err) if cur_err.any?
  #   errors.get(:contacts) ? false : true
  # end
  ########### Note to development team: Evaluate the utility of validate_contacts ##########################

  def validate_callback
    if !callback.is_a?(Hash)
        errors[:callback] << "expecting hash"
      return false
    else
      cb = UrlCallback.new(callback)
      errors[:callback] = cb.errors unless cb.valid?
    end
  end

  def retrieve_registrant
    id = self.saved_registrant
    if id
      found = self.api_requestable.saved_registrants.find_by(id: id.to_i)
      if found
        self.organization = found.company_name
        self.organization_unit = found.department
        self.post_office_box = found.po_box
        self.street_address_1 = found.address1
        self.street_address_2 = found.address2
        self.street_address_3 = found.address3
        self.locality_name = found.city
        self.state_or_province_name = found.state
        self.postal_code = found.postal_code
        self.country = found.country
      else
        errors[:saved_registrant].push(id: "Registrant with id=#{id} does not exist.")
      end
    end
  end

  def retrieve_saved_contact(attributes, extra_attributes=[])
    new_attrs = attributes # { saved_contact: contact_id }
    if attributes && attributes.is_a?(Hash)
      id = attributes[:saved_contact]
      if id
        found = self.api_requestable.all_saved_contacts.find_by(id: id.to_i)
        if found
          keepers = permit_contact_fields + extra_attributes - ['all']
          new_attrs = found.attributes.keep_if {|k,_| keepers.include? k}
        else
          unless extra_attributes.include?('all') && errors[:contacts].count > 1
            errors[:contacts].push(id: "Contact with id=#{id} does not exist.")
          end
        end
      end
    end
    new_attrs
  end

  def is_processing?
    co=@certificate_order || find_certificate_order
    co.is_a?(CertificateOrder) && %w(contacts_provided pending_validation new).
        include?(co.certificate_content&.workflow_state) ? true : false
  end

  def domains
    @domains || parameters_to_hash["domains"]
  end

  def cert_names
    @cert_names || parameters_to_hash["cert_names"]
  end

  def caa_check_domains
    if Settings.enable_caa
      @caa_check_domains || parameters_to_hash["caa_check_domains"]
    else
      ''
    end
  end

  def ref
    super
  end

  def test_update_dcv
    a=ApiCertificateCreate_v1_4.find{|a|a.domains && (a.domains.keys.count) > 2 && a.ref && a.find_certificate_order.try(:external_order_number) && a.find_certificate_order.is_test?}
    a.comodo_auto_update_dcv(send_to_ca: false, certificate_order: a.find_certificate_order)
  end

  def debug_mode?
    self.test && !Rails.env.test?
  end

  def get_domains
    if csr_obj && csr_obj.valid? && domains.nil?
      self.domains={}
      csr_obj.all_names(san: true).each do |name|
        self.domains.merge!({name.downcase => {dcv: 'HTTP_CSR_HASH'}}.with_indifferent_access)
      end
    end

    if domains.is_a? Hash
     domains.keys
    elsif domains.is_a? String
     [domains]
    else
     domains
    end
  end

  def verify_domain_limits
    unless domains.nil?
      max = if is_ucc? || is_evucc?
        500
      elsif is_dv? || is_ev? || is_ov? || is_wildcard?
        1
      elsif is_premium?
        3
      else
        1
      end
      if domains.count > max
        errors[:domains] << "You have exceeded the maximum of #{max} domain(s) or subdomains for this certificate."
      end
    end
  end

  def permit_contact_fields
    CertificateContent::RESELLER_FIELDS_TO_COPY + %w(organization organization_unit country saved_contact)
  end

  def attestation_certificate
    @attestation_certificate || parameters_to_hash["attestation_cert"]
  end

  def attestation_issuer_certificate
    @attestation_issuer_certificate || parameters_to_hash["attestation_issuer_cert"]
  end

  def is_attestation_processing?
    attestation_certificate.blank? && attestation_issuer_certificate.blank? ? false : true
  end

  def attestation_pass?
    verified = verify_signature(
        attestation_issuer_certificate.strip,
        attestation_certificate.strip
    )

    if verified
      AttestationCertificate::ATTESTATION_ROOT_CERTIFICATES.each do |root_cert|
        verified = AttestationCertificate.verify_signature(
            root_cert.strip,
            attestation_issuer_certificate.strip
        )

        break if verified
      end
    end

    return verified
  end

  # def store(cert)
  #   @store ||= OpenSSL::X509::Store.new.tap do |store|
  #     store.set_default_paths
  #     store.add_cert(OpenSSL::X509::Certificate.new(
  #         SignedCertificate.enclose_with_tags(cert))
  #     )
  #   end
  # end

  def create_attestation_certificate(cert, certificate_content, klass)
    attestation_certificate = klass.new
    attestation_certificate.body = cert
    attestation_certificate.type = klass.to_s
    attestation_certificate.certificate_content = certificate_content
    attestation_certificate.status = "stored"
    attestation_certificate.save!
  end
end
