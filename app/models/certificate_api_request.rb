class CertificateApiRequest < ActiveRecord::Base
  serialize :other_domains
  validate :account_key, :secret_key, :product, :period, :server_count,
           :server_software, :csr, :csr_obj, :is_customer_validated,
           :dcv_email_address, :country, presence: true

  #delete below when csr parser can obtain street and zip
  validate :street_address_1, :postal_code, presence: true
  #uncomment below when csr parser can obtain street and zip
#  validate :street_address_1, presence: true, if: lambda{|c|c.csr_obj.street1.blank?}
#  validate :postal_code, presence: true, if: lambda{|c|c.csr_obj.postal_code.blank?}

  validate :other_domains, :domain, :common_names_flag, presence: false, unless: lambda{|c|c.product=~/[md|ucc]/}
  validate :other_domains, presence: true, if: lambda{|c|c.product=~/[md|ucc]/ && c.csr_object.san.blank?}
  validate :common_names_flag, presence: false, unless: lambda{|c|c.product=~/[md]/}
  validate :incorporation_date, :registered_country_name , presence: true, if: lambda{|c|c.product=~/[ev]/}
  validate :registered_locality_name, :registered_state_or_province_name, :registered_country_name,
           :incorporation_date, :assumed_name, presence: false, unless: lambda{|c|c.product=~/[ev]/}
  validate :organization_name, presence: true, if: lambda{|c|c.csr_obj.organization.blank?}
  validate :locality_name, presence: true, if: lambda{|c|c.csr_obj.locality.blank?}
  validate :state_or_province_name, presence: true, if: lambda{|c|c.csr_obj.state.blank?}
  validate :dcv_email_address, :email_address, :contact_email_address, format: :email
  validate :business_category, format: /[bcd]/
  validate :common_names_flag, format: /[01]/

  attribute :csr_obj

  def csr=(csr)
    self[:csr] = csr
    self.csr_obj = Csr.new(body: csr)
  end

  def country=(country)
    self.country=Country.find(c.csr_obj.country || country)
  end

  def server_software=(server_software)
    self.server_software=ServerSoftware.find(server_software)
  end


  t.string :account_key, :secret_key
  t.boolean :test
  t.string :product
  t.integer :period, :server_count
  t.references :server_software
  t.string :other_domains
  t.string :common_names
  t.text :csr
  t.string :organization_name, :post_office_box, :street_address_1 , :street_address_2,
          :street_address_3, :locality_name, :state_or_province_name
  t.references :country
  t.string :duns_number, :company_number, :registered_locality_name, :business_category,
          :email_address, :contact_email_address, :ca_certificate_id
  t. boolean  :hide_certificate_reference
  t.string :external_order_number, :external_order_number_constraint

end
