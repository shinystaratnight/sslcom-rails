require "declarative_authorization/maintenance"

class ApiCertificateCreate_v1_4 < ApiCertificateRequest
  attr_accessor :csr_obj, # temporary csr object
    :certificate_url, :receipt_url, :smart_seal_url, :validation_url,
    :order_number, :order_amount, :order_status

  NON_EV_PERIODS = %w(365 730 1095 1461 1826)
  EV_PERIODS = %w(365 730)
  FREE_PERIODS = %w(30 90)

  PRODUCTS = {:"100"=> "evucc256sslcom", :"101"=>"ucc256sslcom", :"102"=>"ev256sslcom",
              :"103"=>"ov256sslcom", :"104"=>"dv256sslcom", :"105"=>"wc256sslcom", :"106"=>"basic256sslcom",
              :"107"=>"premiumssl256sslcom",
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
  validates :organization_name, presence: true, if: lambda{|c|(!c.is_dv? || c.csr_obj.organization.blank?) && csr}
  validates :post_office_box, presence: {message: "is required if street_address_1 is not specified"},
            if: lambda{|c|!c.is_dv? && c.street_address_1.blank? && csr} #|| c.parsed_field("POST_OFFICE_BOX").blank?}
  validates :street_address_1, presence: {message: "is required if post_office_box is not specified"},
            if: lambda{|c|!c.is_dv? && c.post_office_box.blank? && csr} #|| c.parsed_field("STREET1").blank?}
  validates :locality_name, presence: true, if: lambda{|c|(!c.is_dv? || c.csr_obj.locality.blank?) && csr}
  validates :state_or_province_name, presence: true, if: lambda{|c|(!c.is_dv? || c.csr_obj.state.blank?) && csr}
  validates :postal_code, presence: true, if: lambda{|c|!c.is_dv? && csr} #|| c.parsed_field("POSTAL_CODE").blank?}
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
    # create certificate
    # certificate_order=nil
    if self.ref
      @certificate_order=self.find_certificate_order
      if @certificate_order.is_a?(CertificateOrder)
        certificate_content = @certificate_order.certificate_contents.build
        csr = self.csr_obj
        csr.save
        certificate_content.csr = csr
        certificate_content.server_software_id = server_software
        certificate_content.submit_csr!
        certificate_content.domains = domains.keys
        certificate_content.save
        if errors.blank?
          if certificate_content.valid?
            if certificate_content.save
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
      end
      self
    else
      certificate = Certificate.find_by_serial(PRODUCTS[self.product.to_sym]+api_requestable.reseller_suffix)
      co_params = {duration: period, is_api_call: true, is_test: self.test}
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
      @certificate_order = setup_certificate_order(certificate, co)
      order = api_requestable.purchase(@certificate_order)
      order.cents = @certificate_order.attributes_before_type_cast["amount"].to_f
      unless self.test
        errors[:funded_account] << "Not enough funds in the account to complete this purchase. Please deposit more funds." if
            (order.amount.cents > api_requestable.funded_account.amount.cents)
      end
      if errors.blank?
        if certificate_content.valid? &&
            apply_funds(certificate_order: @certificate_order, ssl_account: api_requestable, order: order)
          if certificate_content.save && csr
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
  end

  def setup_certificate_content(options)
    certificate_order= options[:certificate_order]
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
        c = CertificateContact.new
        r = if options[:contacts] && (options[:contacts][role] || options[:contacts][:all])
              Reseller.new(options[:contacts][role] ? options[:contacts][role] : options[:contacts][:all])
            else
              options[:ssl_account].reseller
            end
        errors[:contacts] = r.errors unless r.valid?
        CertificateContent::RESELLER_FIELDS_TO_COPY.each do |field|
          c.send((field+'=').to_sym, r.send(field.to_sym))
        end
        c.company_name = r.organization
        c.country = Country.find_by_name_caps(r.country.upcase).iso1_code if
            Country.find_by_name_caps(r.country.upcase)
        c.clear_roles
        c.add_role! role
        cc.certificate_contacts << c
        cc.update_attribute(role+"_checkbox", true) unless
          role==CertificateContent::ADMINISTRATIVE_ROLE
      end
      cc.provide_contacts!
      cc.pend_validation! # !certificate_order.is_test
    end
  end

  def setup_certificate_order(certificate, certificate_order)
    duration = self.period
    certificate_order.certificate_content.duration = duration
    if certificate.is_ucc? || certificate.is_wildcard?
      psl = certificate.items_by_server_licenses.find { |item|
        item.value==duration.to_s }
      so  = SubOrderItem.new(:product_variant_item=>psl,
                             :quantity            =>certificate_order.server_licenses.to_i,
                             :amount              =>psl.amount*certificate_order.server_licenses.to_i)
      certificate_order.sub_order_items << so
      if certificate.is_ucc?
        pd                 = certificate.items_by_domains.find_all { |item|
          item.value==duration.to_s }
        additional_domains = (certificate_order.domains.try(:size) || 0) - Certificate::UCC_INITIAL_DOMAINS_BLOCK
        so                 = SubOrderItem.new(:product_variant_item=>pd[0],
                                              :quantity            =>Certificate::UCC_INITIAL_DOMAINS_BLOCK,
                                              :amount              =>pd[0].amount*Certificate::UCC_INITIAL_DOMAINS_BLOCK)
        certificate_order.sub_order_items << so
        # calculate wildcards by subtracting their total from additional_domains
        wildcards = 0
        if certificate.allow_wildcard_ucc? and !certificate_order.domains.blank?
          wildcards = certificate_order.domains.find_all{|d|d =~ /^\*\./}.count
          additional_domains -= wildcards
        end
        if additional_domains > 0
          so = SubOrderItem.new(:product_variant_item=>pd[1],
                                :quantity            =>additional_domains,
                                :amount              =>pd[1].amount*additional_domains)
          certificate_order.sub_order_items << so
        end
        if wildcards > 0
          so = SubOrderItem.new(:product_variant_item=>pd[2],
                                :quantity            =>wildcards,
                                :amount              =>pd[2].amount*wildcards)
          certificate_order.sub_order_items << so
        end
      end
    end
    unless certificate.is_ucc?
      pvi = certificate.items_by_duration.find { |item| item.value==duration.to_s }
      so  = SubOrderItem.new(:product_variant_item=>pvi, :quantity=>1,
                             :amount              =>pvi.amount)
      certificate_order.sub_order_items << so
    end
    certificate_order.amount = certificate_order.
        sub_order_items.map(&:amount).sum
    certificate_order.certificate_contents[0].
        certificate_order    = certificate_order
    certificate_order
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
          self.dcv_email_addresses[k]=ComodoApi.domain_control_email_choices(k).email_address_choices
          errors[:domains] << "domain control validation for #{k} failed. Invalid email address #{v["dcv"]} was submitted but only #{self.dcv_email_addresses[k].join(", ")} are valid choices." unless
              self.dcv_email_addresses[k].include?(v["dcv"])
        end
      end
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
        else Country.find_by_name_caps(attrs[:country].upcase).blank?
          msg = {c_role.to_sym => "The 'country' parameter has an invalid value of #{attrs[:country]}."}
          errors[:contacts].last.merge!(msg)
        end
      end
    end
    return false if errors[:contacts]
  end
end
