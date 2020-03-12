class CertificateApiRequest < ApplicationRecord
  serialize :other_domains
  validates :account_key, :secret_key, :product, :period, :server_count,
           :server_software, :csr, :csr_obj, :is_customer_validated,
           :dcv_email_address, :country, presence: true

  #delete below when csr parser can obtain street and zip
  validates :street_address_1, :postal_code, presence: true
  #uncomment below when csr parser can obtain street and zip
#  validates :street_address_1, presence: true, if: lambda{|c|c.csr_obj.street1.blank?}
#  validates :postal_code, presence: true, if: lambda{|c|c.csr_obj.postal_code.blank?}

  validates :other_domains, :domain, :common_names_flag, presence: false, unless: lambda{|c|c.product=~/[md|ucc]/}
  validates :other_domains, presence: true, if: lambda{|c|c.product=~/[md|ucc]/ && c.csr_object.san.blank?}
  validates :common_names_flag, presence: false, unless: lambda{|c|c.product=~/[md]/}
  validates :incorporation_date, :registered_country_name , presence: true, if: lambda{|c|c.product=~/[ev]/}
  validates :registered_locality_name, :registered_state_or_province_name, :registered_country_name,
           :incorporation_date, :assumed_name, presence: false, unless: lambda{|c|c.product=~/[ev]/}
  validates :organization, presence: true, if: lambda{|c|c.csr_obj.organization.blank?}
  validates :locality_name, presence: true, if: lambda{|c|c.csr_obj.locality.blank?}
  validates :state_or_province_name, presence: true, if: lambda{|c|c.csr_obj.state.blank?}
  validates :dcv_email_address, :email_address, :contact_email_address, email: true
  validates :business_category, format: /[bcd]/
  validates :common_names_flag, format: /[01]/
  
  ERROR_CODES = { 
    #"-1" => "Request was not made over https!",
    "-2" => "'xxxx' is an unrecognised argument!",
    "-3" => "The 'xxxx' argument is missing!",
    "-4" => "The value of the 'xxxx' argument is invalid!",
    "-5" => "The CSR's Common Name may NOT contain a wildcard!",
    "-6" => "The CSR's Common Name MUST contain ONE wildcard!",
    "-7" => "'xx' is not a valid ISO-3166 country!",
    "-8" => "The CSR is missing a required field!",
    "-9" => "The CSR is not valid Base-64 data!",
    "-10" => "The CSR cannot be decoded!",
    "-11" => "The CSR uses an unsupported algorithm!",
    "-12" => "The CSR has an invalid signature!",
    "-13" => "The CSR uses an unsupported key size!",
    "-14" => "An unknown error occurred!",
    "-15" => "Not enough credit!",
    "-16" => "Permission denied! Contact SSL.com Support to enabled api access",
    #"-17" => "Request used GET rather than POST!",
    "-18" => "The CSR's Common Name may not be a Fully-Qualified Domain Name!",
    "-19" => "The CSR's Common Name may not be an Internet-accessible IP Address!",
    "-35" => "The CSR's Common Name may not be an IP Address!",
    "-40" => "The CSR uses a key that is believed to have been compromised!"}

  attribute :csr_obj, Csr.new

  def csr=(csr)
    self.csr_obj = Csr.new(body: csr)
    write_attribute :csr, csr
  end

  def country=(country)
    write_attribute :country, Country.find(c.csr_obj.country || country)
  end

  def server_software=(server_software)
    write_attribute :server_software, ServerSoftware.find(server_software)
  end

end
