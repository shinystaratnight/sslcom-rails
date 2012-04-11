class ApiCertificateRequest < CaApiRequest
  attr_accessor :csr_obj

  validate :access_key, :string_key, :csr, :product, :csr_obj, presence: true
  validate :period, presence: true, format: /\d/, in: NON_EV_PERIODS,
           if: lambda{|c|!(c.is_ev? || c.is_dv?)}
  validate :period, presence: true, format: /\d/, in: EV_PERIODS,
           if: lambda{|c|c.is_ev?}
  validate :server_count, presence: true, if: lambda{|c|c.is_wildcard?}
  validate :server_software, presence: true, format: /\d/, in: ServerSoftware.listing.map(&:id)
  validate :domain, :other_domains, presence: false, if: lambda{|c|!c.is_ucc?}
  validate :organization_name, presence: true, if: lambda{|c|!c.is_dv? || c.csr_obj.organization.blank?}
  validate :street_address_1, presence: true, if: lambda{|c|!c.is_dv?} #|| c.parsed_field("STREET1").blank?}
  validate :locality_name, presence: true, if: lambda{|c|!c.is_dv? || c.csr_obj.locality.blank?}
  validate :state_or_province_name, presence: true, if: lambda{|c|!c.is_dv? || c.csr_obj.state.blank?}
  validate :postal_code, presence: true, if: lambda{|c|!c.is_dv?} #|| c.parsed_field("POSTAL_CODE").blank?}
  validate :country_name, presence: true, if: lambda{|c|c.csr_obj.country.blank?}
  validate :registered_country_name, :incorporation_date, if: lambda{|c|c.is_ev?}
  validate :dcv_email_address, :email_address, :contact_email_address, format: :email
  validate :business_category, format: /[bcd]/
  validate :common_names_flag, format: /[01]/

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

  def csr=(csr)
    self.csr_obj = Csr.new(body: csr)
  end

  def self.apply_for_certificate(certificate)

  end
end
