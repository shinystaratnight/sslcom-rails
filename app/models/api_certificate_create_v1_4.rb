require "declarative_authorization/maintenance"

class ApiCertificateCreate_v1_4 < ApiCertificateRequest
  attr_accessor :csr_obj, # temporary csr object
    :certificate_url, :receipt_url, :smart_seal_url, :validation_url, :order_number, :order_amount, :order_status,
    :api_request, :api_response, :debug, :error_code, :error_message, :eta, :send_to_ca

  NON_EV_PERIODS = %w(365 730 1095 1461 1826)
  EV_PERIODS = %w(365 730)
  FREE_PERIODS = %w(30 90)

  PRODUCTS = {:"100"=> "evucc256sslcom", :"101"=>"ucc256sslcom", :"102"=>"ev256sslcom",
              :"103"=>"ov256sslcom", :"104"=>"dv256sslcom", :"105"=>"wc256sslcom", :"106"=>"basic256sslcom",
              :"107"=>"premium256sslcom",
              :"204"=> "evucc256sslcom", :"202"=>"ucc256sslcom", :"203"=>"ev256sslcom",
              :"200"=>"basic256sslcom", :"201"=>"wc256sslcom"}

  DCV_METHODS = %w(email http_csr_hash cname_csr_hash https_csr_hash)
  DEFAULT_DCV_METHOD = "http_csr_hash"

  validates :account_key, :secret_key, presence: true
  validates :ref, presence: true, if: lambda{|c|['update_v1_4', 'show_v1_4'].include?(c.action)}
  validates :csr, presence: true, unless: "ref.blank?"
  validates :period, presence: true, format: /\d+/,
    inclusion: {in: ApiCertificateCreate::NON_EV_PERIODS,
    message: "needs to be one of the following: #{NON_EV_PERIODS.join(', ')}"}, if: lambda{|c| (c.is_dv? || is_ov?) &&
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
  validates :organization_name, presence: true, if: lambda{|c| csr && (!c.is_dv? || c.csr_obj.organization.blank?)}
  validates :post_office_box, presence: {message: "is required if street_address_1 is not specified"},
            if: lambda{|c|!c.is_dv? && c.street_address_1.blank? && csr} #|| c.parsed_field("POST_OFFICE_BOX").blank?}
  validates :street_address_1, presence: {message: "is required if post_office_box is not specified"},
            if: lambda{|c|!c.is_dv? && c.post_office_box.blank? && csr} #|| c.parsed_field("STREET1").blank?}
  validates :locality_name, presence: true, if: lambda{|c| csr && (!c.is_dv? || c.csr_obj.locality.blank?)}
  validates :state_or_province_name, presence: true, if: lambda{|c|csr && (!c.is_dv? || c.csr_obj.state.blank?)}
  validates :postal_code, presence: true, if: lambda{|c|csr && !c.is_dv?} #|| c.parsed_field("POSTAL_CODE").blank?}
  validates :country_name, presence: true, inclusion:
      {in: Country.accepted_countries, message: "needs to be one of the following: #{Country.accepted_countries.join(', ')}"},
      if: lambda{|c|c.csr_obj && c.csr_obj.country.try("blank?") && csr}
  #validates :registered_country_name, :incorporation_date, if: lambda{|c|c.is_ev?}
  validates :dcv_method, inclusion: {in: ApiCertificateCreate::DCV_METHODS,
      message: "needs to one of the following: #{DCV_METHODS.join(', ')}"}, if: lambda{|c|c.dcv_method}
  validates :contact_email_address, email: true, unless: lambda{|c|c.contact_email_address.blank?}
  validates :business_category, format: {with: /[bcd]/}, unless: lambda{|c|c.business_category.blank?}
  validates :common_names_flag, format: {with: /[01]/}, unless: lambda{|c|c.common_names_flag.blank?}
  # use code instead of serial allows attribute changes without affecting the cert name
  validate :verify_dcv_email_address, on: :create, unless: "domains.blank?"
  validate :validate_contacts, unless: "contacts.blank?"

  before_validation do
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
    certificate = Certificate.find_by_serial(PRODUCTS[self.product.to_sym]+api_requestable.reseller_suffix)
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
    @certificate_order = Order.setup_certificate_order(certificate: @certificate, certificate_order: co,
                                                       duration: self.period)
    order = api_requestable.purchase(@certificate_order)
    order.cents = @certificate_order.attributes_before_type_cast["amount"].to_f
    unless self.test
      errors[:funded_account] << "Not enough funds in the account to complete this purchase. Please deposit more funds." if
          (order.amount.cents > api_requestable.funded_account.amount.cents)
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
              ssl_account: api_requestable,
              contacts: self.contacts)
          return @certificate_order
        else
          return certificate_content
        end
      end
    end
    self
  end

  def setup_certificate_content(options)
    cc = options[:certificate_content]
    cc.dcv_domains({domains: self.domains, emails: self.dcv_email_addresses})
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
        country: self.country_name)
    if cc.csr_submitted?
      cc.provide_info!
      CertificateContent::CONTACT_ROLES.each do |role|
        c = if options[:contacts] && (options[:contacts][role] || options[:contacts][:all])
              CertificateContact.new(options[:contacts][role] ? options[:contacts][role] : options[:contacts][:all])
            else
              CertificateContact.new.attributes.merge! options[:ssl_account].reseller.attributes #test for existence
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
      cc.pend_validation!(ca_certificate_id: ca_certificate_id, send_to_ca: send_to_ca || true)
    end
  end

  def apply_funds(options)
    order = options[:order]
    funded_account = options[:ssl_account].funded_account
    funded_account.cents -= order.cents unless @certificate_order.is_test
    if funded_account.cents >= 0 and order.line_items.size > 0
      funded_account.deduct_order = true
      if order.cents > 0
        order.save
        order.mark_paid!
      end
      Authorization::Maintenance::without_access_control do
        funded_account.save unless @certificate_order.is_test
      end
      options[:certificate_order].pay! true
    end
  end

  def serial
    PRODUCTS[self.product.to_sym] if product
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
  def verify_dcv_email_address
    self.dcv_email_addresses = {}
    self.domains.each do |k,v|
      unless v["dcv"] =~ /https?/i || v["dcv"] =~ /cname/i
        unless v["dcv"]=~EmailValidator::EMAIL_FORMAT
          errors[:domains] << "domain control validation for #{k} failed. #{v["dcv"]} is an invalid email address."
        else
          self.dcv_email_addresses[k]=[]
          # self.dcv_email_addresses[k]=ComodoApi.domain_control_email_choices(k).email_address_choices
          # errors[:domains] << "domain control validation for #{k} failed. Invalid email address #{v["dcv"]} was submitted but only #{self.dcv_email_addresses[k].join(", ")} are valid choices." unless
          #     self.dcv_email_addresses[k].include?(v["dcv"])
        end
      end
      v["failure_action"] ||= "ignore"
    end
  end

  def validate_contacts
    errors[:contacts] = {}
    CertificateContent::CONTACT_ROLES.each do |role|
      if contacts && (contacts[role] || contacts[:all])
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
      end
    end

    # CertificateContent::CONTACT_ROLES.each do |role|
    #   c = CertificateContact.new
    #   r = if contacts && (contacts[role] || contacts[:all])
    #         Reseller.new(contacts[role] ? contacts[role] : contacts[:all])
    #       else
    #         options[:ssl_account].reseller #test for existence
    #       end
    #   errors[:contacts]<<{role.to_sym => r.errors} unless r.valid?
    # end
    #
    return false if errors[:contacts]
  end
end
