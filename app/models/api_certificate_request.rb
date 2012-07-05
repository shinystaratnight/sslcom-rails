class ApiCertificateRequest < CaApiRequest
  attr_accessor :csr_obj

  NON_EV_PERIODS = [365, 730, 1095, 1461, 1826]
  EV_PERIODS = [365, 730]

  PRODUCTS = {:"100"=> "evucc256sslcom", :"101"=>"ucc256sslcom", :"102"=>"ev256sslcom",
              :"103"=>"ov256sslcom", :"104"=>"dv256sslcom", :"105"=>"wc256sslcom"}

  validates :account_key, :secret_key, :csr, :csr_obj, presence: true
  validates :period, presence: true, format: /\d+/, inclusion: {in: NON_EV_PERIODS},
           if: lambda{|c|!(c.is_ev? || c.is_dv?)}
  validates :period, presence: true, format: {with: /\d+/}, inclusion: {in: EV_PERIODS},
           if: lambda{|c|c.is_ev?}
  validates :server_count, presence: true, if: lambda{|c|c.is_wildcard?}
  validates :server_software, presence: true, format: {with: /\d+/}, inclusion:
      {in: ServerSoftware.all.map(&:id), message: "%{value} is not a valid server software"}
  validates :domain, :other_domains, presence: true, if: lambda{|c|c.is_ucc?}
  validates :organization_name, presence: true, if: lambda{|c|!c.is_dv? || c.csr_obj.organization.blank?}
  validates :street_address_1, presence: true, if: lambda{|c|!c.is_dv?} #|| c.parsed_field("STREET1").blank?}
  validates :locality_name, presence: true, if: lambda{|c|!c.is_dv? || c.csr_obj.locality.blank?}
  validates :state_or_province_name, presence: true, if: lambda{|c|!c.is_dv? || c.csr_obj.state.blank?}
  validates :postal_code, presence: true, if: lambda{|c|!c.is_dv?} #|| c.parsed_field("POSTAL_CODE").blank?}
  validates :country_name, presence: true, inclusion:
      {in: Country.accepted_countries, message: "%{value} is not a valid ISO3166 2-character country code"},
           if: lambda{|c|c.csr_obj.try "country.blank?"}
  #validates :registered_country_name, :incorporation_date, if: lambda{|c|c.is_ev?}
  validates :dcv_email_address, :email_address, :contact_email_address, email: true
  validates :business_category, format: {with: /[bcd]/}
  validates :common_names_flag, format: {with: /[01]/}
  validates :product, presence: true, format: {with: /\d{3}/}, inclusion: {in: PRODUCTS.keys.map(&:to_s)} #use code instead of serial allows attribute changes without affecting the cert name
  validates :is_customer_validated, format: {with: /(y|n|yes|no|true|false|1|0)/i}
  validates :is_customer_validated, presence: true, unless: lambda{|c|c.is_dv? && c.csr_obj.is_intranet?}
  #validate  :common_name, :is_not_ip, if: lambda{|c|!c.is_dv?}

  ACCESSORS = [:account_key, :secret_key, :product, :period, :server_count, :server_software, :other_domains,
      :domain, :common_names_flag, :csr, :organization_name, :organization_unit_name, :post_office_box,
      :street_address_1, :street_address_2, :street_address_3, :locality_name, :state_or_province_name,
      :postal_code, :country_name, :duns_number, :company_number, :registered_locality_name,
      :registered_state_or_province_name, :registered_country_name, :incorporation_date,
      :assumed_name, :business_category, :email_address, :contact_email_address, :dcv_email_address,
      :ca_certificate_id, :is_customer_validated, :hide_certificate_reference, :external_order_number]

  attr_accessor *ACCESSORS

  def csr=(csr)
    self.csr_obj = Csr.new(body: csr)
  end

  def self.apply_for_certificate(certificate)

  end

  def is_ev?
    product =~ /ev/
  end

  def is_dv?
    product =~ /dv/
  end

  def is_wildcard?
    product =~ /wildcard/
  end

  def is_ucc?
    product =~ /wildcard/
  end

  def is_not_ip
    true
  end

end
