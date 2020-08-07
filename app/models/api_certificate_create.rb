require "declarative_authorization/maintenance"

class ApiCertificateCreate < ApiCertificateRequest
  attr_accessor :csr_obj, # temporary csr object
    :certificate_url, :receipt_url, :smart_seal_url, :validation_url,
    :order_number, :order_amount, :order_status

  NON_EV_SSL_PERIODS = %w(365 730 1095 1461 1826)
  EV_SSL_PERIODS = %w(365 730)
  EV_CS_PERIODS = %w(365 730 1095)
  FREE_PERIODS = %w(30 90)

  DCV_METHODS = %w(email http_csr_hash cname_csr_hash https_csr_hash)

  validates :account_key, :secret_key, :csr, presence: true
  validates :period, presence: true, format: /\d+/,
    inclusion: {in: ApiCertificateRequest::NON_EV_SSL_PERIODS,
    message: "needs to be one of the following: #{NON_EV_SSL_PERIODS.join(', ')}"}, if: lambda{|c|!(c.is_ev? || c.is_dv?)}
  validates :period, presence: true, format: {with: /\d+/},
    inclusion: {in: ApiCertificateRequest::EV_SSL_PERIODS,
    message: "needs to be one of the following: #{EV_SSL_PERIODS.join(', ')}"}, if: lambda{|c|c.is_ev?}
  # validates :server_count, presence: true, if: lambda{|c|c.is_wildcard?}
  validates :server_software, presence: true, format: {with: /\d+/}, inclusion:
      {in: ServerSoftware.pluck(:id).map(&:to_s),
      message: "needs to be one of the following: #{ServerSoftware.pluck(:id).map(&:to_s).join(', ')}"},
      if: -> { Settings.require_server_software_w_csr_submit }
  validates :organization, presence: true, if: lambda{|c|!c.is_dv? || c.csr_obj.organization.blank?}
  validates :post_office_box, presence: {message: "is required if street_address_1 is not specified"},
            if: lambda{|c|!c.is_dv? && c.street_address_1.blank?} #|| c.parsed_field("POST_OFFICE_BOX").blank?}
  validates :street_address_1, presence: {message: "is required if post_office_box is not specified"},
            if: lambda{|c|!c.is_dv? && c.post_office_box.blank?} #|| c.parsed_field("STREET1").blank?}
  validates :locality_name, presence: true, if: lambda{|c|!c.is_dv? || c.csr_obj.locality.blank?}
  validates :state_or_province_name, presence: true, if: lambda{|c|!c.is_dv? || c.csr_obj.state.blank?}
  validates :postal_code, presence: true, if: lambda{|c|!c.is_dv?} #|| c.parsed_field("POSTAL_CODE").blank?}
  validates :country, presence: true, inclusion:
      {in: Country.accepted_countries, message: "needs to be one of the following: #{Country.accepted_countries.join(', ')}"},
      if: lambda{|c|c.csr_obj && c.csr_obj.country.try("blank?")}
  #validates :registered_country, :incorporation_date, if: lambda{|c|c.is_ev?}
  validates :dcv_email_address, email: true, unless: lambda{|c|c.dcv_email_address.blank?}
  validates :dcv_method, inclusion: {in: ApiCertificateCreate::DCV_METHODS,
      message: "needs to one of the following: #{DCV_METHODS.join(', ')}"}, if: lambda{|c|c.dcv_method}
  validates :email_address, email: true, unless: lambda{|c|c.email_address.blank?}
  validates :contact_email_address, email: true, unless: lambda{|c|c.contact_email_address.blank?}
  validates :business_category, format: {with: /[bcd]/}, unless: lambda{|c|c.business_category.blank?}
  validates :common_names_flag, format: {with: /[01]/}, unless: lambda{|c|c.common_names_flag.blank?}
  # use code instead of serial allows attribute changes without affecting the cert name
  validates :product, presence: true, format: {with: /\d{3}/},
            inclusion: {in: PRODUCTS.keys.map(&:to_s),
            message: "needs to one of the following: #{PRODUCTS.keys.map(&:to_s).join(', ')}"}
  validates :is_customer_validated, format: {with: /(y|n|yes|no|true|false|1|0)/i}
  validates :is_customer_validated, presence: true, unless: lambda{|c|c.is_dv? && c.csr_obj.is_intranet?}
  #validate  :common_name, :is_not_ip, if: lambda{|c|!c.is_dv?}
  validates_presence_of :verify_dcv_email_address, on: :create

  before_validation do
    if new_record?
      if self.csr # a single domain validation
        self.dcv_method ||= "http_csr_hash"
        self.csr_obj = Csr.new(body: self.csr) # this is only for validation and does not save
        unless self.csr_obj.errors.empty?
          self.errors[:csr] << "has problems and or errors"
        end
      elsif self.api_requestable.is_a?(CertificateName) # a multi domain validation
      end
    end
  end

  def create_certificate_order
    # create certificate
    @certificate = Certificate.find_by_serial(PRODUCTS[self.product.to_sym])
    co_params = {duration: period}
    co_params.merge!({is_test: self.test})
    co_params.merge!({domains: self.domains}) if(is_ucc? && self.domains)
    csr = self.csr_obj
    csr.save
    certificate_order = api_requestable.certificate_orders.build(co_params)
    certificate_content=CertificateContent.new(
        csr: csr, server_software_id: self.server_software)
    certificate_order.certificate_contents << certificate_content
    @certificate_order = Order.setup_certificate_order(certificate: @certificate, certificate_order: certificate_order,
      duration: self.period)
    @certificate_order.renewal = self.api_requestable.certificate_orders.find_by_ref(self.renewal_id) if self.renewal_id
    order = api_requestable.purchase(@certificate_order)
    order.cents = @certificate_order.attributes_before_type_cast["amount"].to_f
    unless self.test
      errors[:funded_account] << "Not enough funds in the account to complete this purchase. Please deposit more funds." if
        (order.amount.cents > api_requestable.funded_account.amount.cents)
    end
    if errors.blank?
      if certificate_content.valid? &&
          apply_funds(certificate_order: @certificate_order, ssl_account: api_requestable, order: order)
        if certificate_content.save
          setup_certificate_content(
              certificate_order: certificate_order,
              certificate_content: certificate_content,
              ssl_account: api_requestable)
        end
        return @certificate_order
      else
        return certificate_content
      end
    end
    errors
  end

  def setup_certificate_content(options)
    certificate_order= options[:certificate_order]
    cc = options[:certificate_content]
    cc.add_ca(options[:certificate_order].ssl_account) if options[:certificate_order].external_order_number.blank?
    cc.create_registrant(
        company_name: self.organization,
        department: self.organization_unit,
        po_box: self.post_office_box,
        address1: self.street_address_1,
        address2: self.street_address_2,
        address3: self.street_address_3,
        city: self.locality_name,
        state: self.state_or_province_name,
        postal_code: self.postal_code,
        country: self.country)
    if cc.csr_submitted?
      cc.provide_info!
      CertificateContent::CONTACT_ROLES.each do |role|
        c = CertificateContact.new
        r = options[:ssl_account].reseller
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

  def verify_dcv_email_address
    if self.dcv_methods

    elsif self.dcv_email_address
      emails=ComodoApi.domain_control_email_choices(self.domain ? self.domain :
                                                        self.csr_obj.common_name).email_address_choices
      errors[:dcv_email_address]<< "must be one of the following: #{emails.join(", ")}" unless
          emails.include?(self.dcv_email_address)
    end
  end
end
