require "declarative_authorization/maintenance"

class ApiCertificateReprocess < ApiCertificateRequest
  attr_accessor :csr_obj, :certificate_url, :receipt_url, :smart_seal_url, :validation_url,
    :order_number, :order_amount, :order_status

  NON_EV_PERIODS = %w(365 730 1095 1461 1826)
  EV_PERIODS = %w(365 730)

  PRODUCTS = {:"100"=> "evucc256sslcom", :"101"=>"ucc256sslcom", :"102"=>"ev256sslcom",
              :"103"=>"ov256sslcom", :"104"=>"dv256sslcom", :"105"=>"wc256sslcom", :"106"=>"basic256sslcom",
              :"107"=>"premiumssl256sslcom",
              :"204"=> "evucc256sslcom", :"202"=>"ucc256sslcom", :"203"=>"ev256sslcom",
              :"200"=>"basic256sslcom", :"201"=>"wc256sslcom"}

  validates :account_key, :secret_key, :csr, :ref, presence: true
  validates :period, presence: true, format: /\d+/,
    inclusion: {in: ApiCertificateCreate::NON_EV_PERIODS,
    message: "needs to be one of the following: #{ApiCertificateCreate::NON_EV_PERIODS.join(', ')}"}, if: lambda{|c|!(c.is_ev? || c.is_dv?)}
  validates :period, presence: true, format: {with: /\d+/},
    inclusion: {in: ApiCertificateCreate::EV_PERIODS,
    message: "needs to be one of the following: #{ApiCertificateCreate::EV_PERIODS.join(', ')}"}, if: lambda{|c|c.is_ev?}
  # validates :server_count, presence: true, if: lambda{|c|c.is_wildcard?}
  validates :server_software, presence: true, format: {with: /\d+/}, inclusion:
      {in: ServerSoftware.pluck(:id).map(&:to_s),
      message: "needs to be one of the following: #{ServerSoftware.pluck(:id).map(&:to_s).join(', ')}"}
  validates :organization_name, presence: true, if: lambda{|c|!c.is_dv? || c.csr_obj.organization.blank?}
  validates :post_office_box, presence: {message: "is required if street_address_1 is not specified"},
            if: lambda{|c|!c.is_dv? && c.street_address_1.blank?} #|| c.parsed_field("POST_OFFICE_BOX").blank?}
  validates :street_address_1, presence: {message: "is required if post_office_box is not specified"},
            if: lambda{|c|!c.is_dv? && c.post_office_box.blank?} #|| c.parsed_field("STREET1").blank?}
  validates :locality_name, presence: true, if: lambda{|c|!c.is_dv? || c.csr_obj.locality.blank?}
  validates :state_or_province_name, presence: true, if: lambda{|c|!c.is_dv? || c.csr_obj.state.blank?}
  validates :postal_code, presence: true, if: lambda{|c|!c.is_dv?} #|| c.parsed_field("POSTAL_CODE").blank?}
  validates :country_name, presence: true, inclusion:
      {in: Country.accepted_countries, message: "needs to be one of the following: #{Country.accepted_countries.join(', ')}"},
      if: lambda{|c|c.csr_obj && c.csr_obj.country.try("blank?")}
  #validates :registered_country_name, :incorporation_date, if: lambda{|c|c.is_ev?}
  validates :dcv_email_address, email: true, unless: lambda{|c|c.dcv_email_address.blank?}
  validates :dcv_method, inclusion: {in: ApiCertificateCreate::DCV_METHODS,
      message: "needs to one of the following: #{ApiCertificateCreate::DCV_METHODS.join(', ')}"}, if: lambda{|c|c.dcv_method}
  validates :email_address, email: true, unless: lambda{|c|c.email_address.blank?}
  validates :contact_email_address, email: true, unless: lambda{|c|c.contact_email_address.blank?}
  validates :business_category, format: {with: /[bcd]/}, unless: lambda{|c|c.business_category.blank?}
  validates :common_names_flag, format: {with: /[01]/}, unless: lambda{|c|c.common_names_flag.blank?}
  # use code instead of serial allows attribute changes without affecting the cert name
  validates :product, presence: true, format: {with: /\d{3}/},
            inclusion: {in: ApiCertificateCreate::PRODUCTS.keys.map(&:to_s),
            message: "needs to one of the following: #{ApiCertificateCreate::PRODUCTS.keys.map(&:to_s).join(', ')}"}
  validates :is_customer_validated, format: {with: /(y|n|yes|no|true|false|1|0)/i}
  validates :is_customer_validated, presence: true, unless: lambda{|c|c.is_dv? && c.csr_obj.is_intranet?}
  #validate  :common_name, :is_not_ip, if: lambda{|c|!c.is_dv?}
  validate :verify_dcv_methods, on: :create

  after_initialize do
    if new_record? && self.csr
      self.dcv_method ||= "http_csr_hash"
      self.csr_obj = Csr.new(body: self.csr)
      unless self.csr_obj.errors.empty?
        self.errors[:csr] << "has problems and or errors"
      end
    end
  end

  #TODO finish this
  def verify_dcv_methods
    # if non ucc then look for email address, http_csr_hash, or dns
    #if self.dcv_email_address && dcv_method=="http_csr_hash"
    #  emails=ComodoApi.domain_control_email_choices(self.domain ? self.domain :
    #                                                    self.csr_obj.common_name).email_address_choices
    #  errors[:dcv_email_address]<< "must be one of the following: #{emails.join(", ")}" unless
    #      emails.include?(self.dcv_email_address)
    #end
    true
  end

  def create_certificate_order
    # create certificate
    @certificate = Certificate.find_by_serial(PRODUCTS[self.product.to_sym])
    co_params = {duration: period, is_api_call: true}
    co_params.merge!({is_test: self.test})
    co_params.merge!({domains: self.domains}) if(is_ucc? && self.domains)
    certificate_order = current_user.ssl_account.certificate_orders.build(co_params)
    certificate_content=certificate_order.certificate_contents.build(
        csr: self.csr_obj, server_software_id: self.server_software)
    certificate_content.certificate_order = certificate_order
    @certificate_order = setup_certificate_order(@certificate, certificate_order)
    order = current_user.ssl_account.purchase(@certificate_order)
    order.cents = @certificate_order.attributes_before_type_cast["amount"].to_f
    unless self.test
      errors[:funded_account] << "Not enough funds in the account to complete this purchase. Please deposit more funds." if
        (order.amount.cents > current_user.ssl_account.funded_account.amount.cents)
    end
    if errors.blank?
      if certificate_content.valid? &&
          apply_funds(certificate_order: @certificate_order, current_user: current_user, order: order)
        if certificate_content.save
          setup_certificate_content(
              certificate_order: certificate_order,
              certificate_content: certificate_content,
              current_user: current_user)
        end
        return @certificate_order
      else
        return certificate_content
      end
    end
  end

  def setup_certificate_content(options)
    certificate_order= options[:certificate_order]
    cc = options[:certificate_content]
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
        r = options[:current_user].ssl_account.reseller
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
      cc.pend_validation! !certificate_order.is_test
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
        if additional_domains > 0
          so = SubOrderItem.new(:product_variant_item=>pd[1],
                                :quantity            =>additional_domains,
                                :amount              =>pd[1].amount*additional_domains)
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
    @account_total = funded_account = options[:current_user].ssl_account.funded_account
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
    serial =~ /^dv/ if serial
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

end
