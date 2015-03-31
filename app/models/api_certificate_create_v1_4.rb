require "declarative_authorization/maintenance"

class ApiCertificateCreate_v1_4 < ApiCertificateRequest
  attr_accessor :csr_obj, # temporary csr object
    :certificate_url, :receipt_url, :smart_seal_url, :validation_url, :order_number, :order_amount, :order_status,
    :api_request, :api_response, :error_code, :error_message, :eta, :send_to_ca, :ref

  NON_EV_PERIODS = %w(365 730 1095 1461 1826)
  EV_PERIODS = %w(365 730)
  FREE_PERIODS = %w(30 90)
  DCV_FAILURE_ACTIONS = %w(remove ignore)

  PRODUCTS = {"100"=> "evucc256sslcom", "101"=>"ucc256sslcom", "102"=>"ev256sslcom",
              "103"=>"ov256sslcom", "104"=>"dv256sslcom", "105"=>"wc256sslcom", "106"=>"basic256sslcom",
              "107"=>"premium256sslcom",
              "204"=> "evucc256sslcom", "202"=>"ucc256sslcom", "203"=>"ev256sslcom",
              "200"=>"basic256sslcom", "201"=>"wc256sslcom"}

  DCV_METHODS = %w(email http_csr_hash cname_csr_hash https_csr_hash)
  DEFAULT_DCV_METHOD = "http_csr_hash"
  DEFAULT_DCV_METHOD_COMODO = "HTTPCSRHASH"

  validates :account_key, :secret_key, presence: true
  validates :ref, presence: true, if: lambda{|c|['update_v1_4', 'show_v1_4'].include?(c.action)}
  validates :csr, presence: true, unless: "ref.blank? || is_processing?"
  validates :period, presence: true, format: /\d+/,
    inclusion: {in: ApiCertificateCreate::NON_EV_PERIODS,
    message: "needs to be one of the following: #{NON_EV_PERIODS.join(', ')}"}, if: lambda{|c| (c.is_dv? || c.is_ov?) &&
          !c.is_free? && c.ref.blank? && ['create_v1_4'].include?(c.action)}
  validates :period, presence: true, format: {with: /\d+/},
    inclusion: {in: ApiCertificateCreate::EV_PERIODS,
    message: "needs to be one of the following: #{EV_PERIODS.join(', ')}"}, if: lambda{|c|c.is_ev? && c.ref.blank? &&
    ['create_v1_4'].include?(c.action)}
  validates :period, presence: true, format: {with: /\d+/},
    inclusion: {in: ApiCertificateCreate::FREE_PERIODS,
    message: "needs to be one of the following: #{FREE_PERIODS.join(', ')}"}, if: lambda{|c|c.is_free? && c.ref.blank? &&
    ['create_v1_4'].include?(c.action)}
  validates :product, presence: true, format: {with: /\d{3}/},
      inclusion: {in: ApiCertificateCreate::PRODUCTS.keys.map(&:to_s),
      message: "needs to one of the following: #{PRODUCTS.keys.map(&:to_s).join(', ')}"}, if:
      lambda{|c|['create_v1_4'].include?(c.action)}
  validates :server_software, presence: true, format: {with: /\d+/}, inclusion:
      {in: ServerSoftware.pluck(:id).map(&:to_s),
      message: "needs to be one of the following: #{ServerSoftware.pluck(:id).map(&:to_s).join(', ')}"}, unless: "csr.blank?"
  validates :organization_name, presence: true, if: lambda{|c|c.csr && (!c.is_dv? || c.csr_obj.organization.blank?)}
  validates :post_office_box, presence: {message: "is required if street_address_1 is not specified"},
            if: lambda{|c|!c.is_dv? && c.street_address_1.blank? && c.csr} #|| c.parsed_field("POST_OFFICE_BOX").blank?}
  validates :street_address_1, presence: {message: "is required if post_office_box is not specified"},
            if: lambda{|c|!c.is_dv? && c.post_office_box.blank? &&c.csr} #|| c.parsed_field("STREET1").blank?}
  validates :locality_name, presence: true, if: lambda{|c|c.csr && (!c.is_dv? || c.csr_obj.locality.blank?)}
  validates :state_or_province_name, presence: true, if: lambda{|c|csr && (!c.is_dv? || c.csr_obj.state.blank?)}
  validates :postal_code, presence: true, if: lambda{|c|c.csr && !c.is_dv?} #|| c.parsed_field("POSTAL_CODE").blank?}
  validates :country_name, presence: true, inclusion:
      {in: Country.accepted_countries, message: "needs to be one of the following: #{Country.accepted_countries.join(', ')}"},
      if: lambda{|c| c.csr && c.csr_obj && c.csr_obj.country.try("blank?")}
  #validates :registered_country_name, :incorporation_date, if: lambda{|c|c.is_ev?}
  validates :dcv_method, inclusion: {in: ApiCertificateCreate::DCV_METHODS,
      message: "needs to one of the following: #{DCV_METHODS.join(', ')}"}, if: lambda{|c|c.dcv_method}
  validates :contact_email_address, email: true, unless: lambda{|c|c.contact_email_address.blank?}
  validates :business_category, format: {with: /[bcd]/}, unless: lambda{|c|c.business_category.blank?}
  validates :common_names_flag, format: {with: /[01]/}, unless: lambda{|c|c.common_names_flag.blank?}
  # use code instead of serial allows attribute changes without affecting the cert name
  validate :verify_dcv, on: :create, if: "!domains.blank?"
  validate :validate_contacts, if: "api_requestable && api_requestable.reseller.blank? && !csr.blank?"

  before_validation do
    self.period = period.to_s unless period.blank?
    self.product = product.to_s unless product.blank?
    if new_record?
      if self.csr # a single domain validation
        self.dcv_method ||= "http_csr_hash"
        self.csr_obj = Csr.new(body: self.csr) # this is only for validation and does not save
        unless self.csr_obj.errors.empty?
          self.errors[:csr] << "has problems and or errors"
        end
      elsif self.api_requestable.is_a?(CertificateName) # a multi domain validation
        #TODO add dcv validation
      end
    end
  end

  def create_certificate_order
    certificate = Certificate.find_by_serial(PRODUCTS[self.product.to_s]+api_requestable.reseller_suffix)
    co_params = {duration: period, is_test: self.test}
    co = api_requestable.certificate_orders.build(co_params)
    if self.csr
      # process csr
      csr = self.csr_obj
      csr.save
    else
      # or make a certificate voucher
      co.preferred_payment_order = 'prepaid'
    end
    domain_names = if self.domains.is_a? Hash
                     self.domains.keys
                   elsif self.domains.is_a? String
                     [self.domains]
                   else
                     self.domains
                   end
    certificate_content=CertificateContent.new(
        csr: csr, server_software_id: self.server_software, domains: domain_names)
    co.certificate_contents << certificate_content
    @certificate_order = Order.setup_certificate_order(certificate: certificate, certificate_order: co,
                                                       duration: self.period.to_i/365)
    order = api_requestable.purchase(@certificate_order)
    order.cents = @certificate_order.attributes_before_type_cast["amount"].to_f
    unless self.test
      if false #credit_card

      else
        errors[:funded_account] << "Not enough funds in the account to complete this purchase. Please deposit more funds." if
            (order.amount.cents > api_requestable.funded_account.amount.cents)
      end
    end
    if errors.blank?
      if certificate_content.valid? &&
          apply_funds(certificate_order: @certificate_order, ssl_account: api_requestable, order: order)
        if csr && certificate_content.save
          setup_certificate_content(
              certificate_order: @certificate_order,
              certificate_content: certificate_content,
              ssl_account: api_requestable,
              contacts: self.contacts)
        end
        return @certificate_order
      else
        return certificate_content
      end
    end
    self
  end

  def update_certificate_order
    @certificate_order=self.find_certificate_order
    if @certificate_order.is_a?(CertificateOrder)
      @certificate_order.update_attribute(:external_order_number, self.ca_order_number) if (self.admin_submitted && self.ca_order_number)
      # choose the right ca_certificate_id for submit to Comodo
      @certificate_order.is_test=self.test
      #assume updating domain validation, already sent to comodo
      if @certificate_order.certificate_content && @certificate_order.certificate_content.pending_validation?
        #set domains
        @certificate_order.certificate_content.update_attribute(:domains, self.domains.keys)
        @certificate_order.certificate_content.dcv_domains({domains: self.domains, emails: self.dcv_candidate_addresses})
        #send to comodo
        comodo_auto_update_dcv(certificate_order: @certificate_order)
      else
        if self.csr_obj
          certificate_content = @certificate_order.certificate_contents.build
          csr = self.csr_obj
          csr.save
          certificate_content.csr = csr
          certificate_content.server_software_id = server_software
          certificate_content.submit_csr!
          certificate_content.domains = domains.keys unless domains.blank?
          if errors.blank?
            if certificate_content.save
              setup_certificate_content(
                  certificate_order: @certificate_order,
                  certificate_content: certificate_content,
                  contacts: self.contacts)
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

  # this update dcv method to comodo for each domain
  def comodo_auto_update_dcv(options={send_to_ca: true})
    self.domains.keys.map do |domain|
      # ComodoApi.delay.auto_update_dcv(dcv:
      ComodoApi.auto_update_dcv(dcv:
        options[:certificate_order].certificate_content.certificate_names.find_by_name(domain).
        domain_control_validations.last, send_to_ca: options[:send_to_ca])
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
    cc.create_registrant(
        company_name: self.organization_name,
        department: self.organization_unit_name,
        po_box: self.post_office_box,
        address1: self.street_address_1,
        address2: self.street_address_2,
        address3: self.street_address_3,
        city: self.locality_name,
        state: self.state_or_province_name,
        postal_code: self.postal_code,
        country: self.country_name || csr_obj.country)
    if cc.csr_submitted?
      cc.provide_info!
      CertificateContent::CONTACT_ROLES.each do |role|
        c = if options[:contacts] && (options[:contacts][role] || options[:contacts][:all])
              CertificateContact.new(options[:contacts][role] ? options[:contacts][role] : options[:contacts][:all])
            else
              attributes = api_requestable.reseller.attributes.select do |attr, value|
                (CertificateContact.column_names-%w(id created_at)).include?(attr.to_s)
              end
              contact = CertificateContact.new
              contact.assign_attributes(attributes, :without_protection => true)
              contact
            end
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
      cc.provide_contacts!
      options[:certificate_order].orphaned_certificate_contents remove: true
      # if debugging, we want to see response from Comodo
      send_dcv(cc)
    end
  end

  def send_dcv(cc)
    if self.debug=="true" || self.domains.keys.count <= Validation::COMODO_EMAIL_LOOKUP_THRESHHOLD
      cc.dcv_domains({domains: self.domains, emails: self.dcv_candidate_addresses,
                      dcv_failure_action: self.options.blank? ? nil : self.options['dcv_failure_action']})
      cc.pend_validation!(ca_certificate_id: ca_certificate_id, send_to_ca: send_to_ca || true) unless cc.pending_validation?
    else
      job_group = Delayed::JobGroups::JobGroup.create!
      job_group.enqueue(DomainJob.new(cc, {ca_certificate_id: self.ca_certificate_id, send_to_ca: self.send_to_ca},
                                      self.options.blank? ? nil : self.options['dcv_failure_action'], self.domains,
                                      self.dcv_candidate_addresses))
      job_group.mark_queueing_complete
    end
  end

  def apply_funds(options)
    order = options[:order]
    funded_account = options[:ssl_account].funded_account
    funded_account.cents -= order.cents unless @certificate_order.is_test
    if order.line_items.size > 0
      funded_account.deduct_order = true
      # order.save
      order.mark_paid!
      Authorization::Maintenance::without_access_control do
        funded_account.save unless @certificate_order.is_test
      end
      options[:certificate_order].pay! true
    end
  end

  def serial
    PRODUCTS[self.product.to_s] if product
  end

  def is_ev?
    serial =~ /^ev/ if serial
  end

  def is_dv?
    (serial =~ /^dv/ || serial =~ /^basic/) if serial
  end

  def is_ov?
    !is_ev? && !is_dv?
  end

  def is_free?
    serial =~ /^dv/ if serial
  end

  def is_basic?
    serial =~ /^basic/ if serial
  end

  def is_wildcard?
    serial =~ /^wc/ if serial
  end

  def is_ucc?
    serial =~ /^ucc/ if serial
  end

  def is_not_ip
    true
  end

  # must belong to a list of acceptable email addresses
  def verify_dcv
    #if submitting domains, then a csr must have been submitted on this or a previous request
    if !csr.blank? || is_processing?
      self.dcv_candidate_addresses = {}
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
      errors[:domains] << "csr has not been submitted yet."
    elsif !api_requestable.certificate_content.pending_validation?
      errors[:domains] << "certificate order is not in validation stage."
    else
      errors[:domains] << "domain control validation failed. Please contact support@ssl.com for more information."
    end
  end

  def verify_http_csr_hash
    self.domains.each do |k,v|
      if v["dcv"] =~ /https?/i
        begin
          cn = CertificateName.new(name: k, csr: csr_obj)
          found=Thread.new { cn.dcv_verified? }.join(10)
        rescue StandardError => e
        ensure
          unless found.try(:value)
            if  (v["dcv_failure_action"]=="remove" ||
                (v["dcv_failure_action"].blank? && self.options && self.options["dcv_failure_action"]=="remove"))
              self.domains.delete k
            end
          end
        end
      end
    end
  end

  def validate_contacts
    if contacts
      errors[:contacts] = {}
      CertificateContent::CONTACT_ROLES.each do |role|
        if (contacts[role] || contacts[:all])
          attrs,c_role = contacts[role] ? [contacts[role],role] : [contacts[:all],:all]
          extra = attrs.keys-(CertificateContent::RESELLER_FIELDS_TO_COPY+%w(organization country)).flatten
          if !extra.empty?
            msg = {c_role.to_sym => "The following parameters are invalid: #{extra.join(", ")}"}
            errors[:contacts].last.merge!(msg)
          elsif !CertificateContact.new(attrs.merge({roles: role})).valid?
            r = CertificateContact.new(attrs.merge({roles: role}))
            r.valid?
            errors[:contacts].last.merge!(c_role.to_sym => r.errors)
          elsif Country.find_by_iso1_code(attrs[:country].upcase).blank?
            msg = {c_role.to_sym => "The 'country' parameter has an invalid value of #{attrs[:country]}."}
            errors[:contacts].last.merge!(msg)
          end
        else
          msg = {role.to_sym => "contact information missing"}
          errors[:contacts].last.merge!(msg)
        end
      end
    else
      errors[:contacts] << "parameter required"
    end
    return false if errors[:contacts]
  end

  def is_processing?
    co=@certificate_order || find_certificate_order
    co.is_a?(CertificateOrder) && (co.certificate_content.try("contacts_provided?") ||
        co.certificate_content.try("pending_validation?")) ? true : false
  end

  def domains
    @domains || parameters_to_hash["domains"]
  end

  def ref
    @ref || parameters_to_hash["ref"]
  end

  def test_update_dcv
    a=ApiCertificateCreate_v1_4.find{|a|a.domains && (a.domains.keys.count) > 2 && a.ref && a.find_certificate_order.try(:external_order_number) && a.find_certificate_order.is_test?}
    a.comodo_auto_update_dcv(send_to_ca: false, certificate_order: a.find_certificate_order)
  end
end
