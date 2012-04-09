class ClientOrderCertificateRequest < CaApiRequest
  validate :access_key, presence: true
  validate :string_key, presence: true
  validate :csr, presence: true
  validate :product, presence: true
  validate :period, presence: true, format: /\d/, in: NON_EV_PERIODS, 
           if: lambda{|c|!(c.is_ev? || c.is_dv?)}
  validate :period, presence: true, format: /\d/, in: EV_PERIODS,
           if: lambda{|c|c.is_ev?}
  validate :server_count, presence: true, if: lambda{|c|c.is_wildcard?}
  validate :server_software, presence: true, format: /\d/, in: ServerSoftware.listing.map(&:id)
  validate :other_domains, presence: false, if: lambda{|c|!c.is_ucc?}
  validate :domain, presence: false, if: lambda{|c|!c.is_ucc?}
  validate :organization_name, presence: true, if: lambda{|c|c.parsed_field("OU").blank?}
  validate :street_address_1, presence: true, if: lambda{|c|c.parsed_field("STREET1").blank?}
  validate :locality_name, presence: true, if: lambda{|c|c.parsed_field("LOCALITY").blank?}
  validate :state_or_province_name, presence: true, if: lambda{|c|c.parsed_field("STATE").blank?}
  validate :postal_code, presence: true, if: lambda{|c|c.parsed_field("POSTAL_CODE").blank?}
  validate :country_name, presence: true, if: lambda{|c|c.parsed_field("COUNTRY").blank?}
  validate :registered_country_name, presence: true, 
           if: lambda{|c|c.parsed_field("REGISTERED_COUNTRY").blank? && c.is_ev?}
  validate :incorporation_date, presence: true, 
           if: lambda{|c|c.parsed_field("INCORPORATION_DATE").blank? && c.is_ev?}

  before_create :parse_request

  NON_EV_PERIODS = [365, 730, 1095, 1461, 1826]
  EV_PERIODS = [365, 730]

  PRODUCTS = %w(evssl evmdssl ovssl wcssl mdssl dvssl uccssl)
  
  attr_accessor :account_key, :secret_key, :product, :period, :server_count, :server_software, :other_domains,
    :domain, :common_names_flag, :csr, :organization_name, :organization_unit_name, :post_office_box,
    :street_address_1, :street_address_2, :street_address_3, :locality_name, :state_or_province_name,
    :postal_code, :country_name, :duns_number, :company_number, :registered_locality_name,
    :registered_state_or_province_name, :registered_country_name, :incorporation_date,
    :assumed_name, :business_category, :email_address, :contact_email_address, :dcv_email_address,
    :ca_certificate_id, :is_customer_validated, :hide_certificate_reference, :external_order_number

  def parse_request
    co = CertificateOrder.new
  end


end
