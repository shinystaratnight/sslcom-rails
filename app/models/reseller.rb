class Reseller < ActiveRecord::Base
  belongs_to  :ssl_account
  belongs_to  :reseller_tier
  easy_roles  :roles

  attr_protected  :reseller_tier
  PROFILE_COLUMNS = %w(display_name tagline description)
  COMPANY_COLUMNS = %w(organization website address1 address2 address3
    postal_code city state country)
  ADMIN_COLUMNS = %w(first_name last_name email phone ext fax)
  PAYMENT_COLUMNS = %w(tax_number)
  NONREQUIRED_COLUMNS = %w(ext fax)
  REQUIRED_COLUMNS = %w(type_organization organization website address1
    postal_code city state tax_number country) + ADMIN_COLUMNS -
    NONREQUIRED_COLUMNS
  FORM_COLUMNS=%w(type_organization)+ADMIN_COLUMNS+COMPANY_COLUMNS+
    PAYMENT_COLUMNS
  BUSINESS = "business"
  INDIVIDUAL = "individual"

  SUBDOMAIN = 'reseller'

  TARGETED = %w(host_providers registrars merchants enterprises government
      education medical) - %w(enterprises government
      education medical)

  SIGNUP_PAGES = %w(Reseller\ Profile Select\ Tier Billing\ Information Registration\ Complete)

  validates_presence_of *((REQUIRED_COLUMNS-%w(email organization state)).map(&:intern))
  validates_presence_of :organization, :if => Proc.new{|reseller| reseller.type_organization == BUSINESS }
  validates_length_of   *((FORM_COLUMNS).map(&:intern)+[:maximum => 100])
  validates_length_of   :email, :within => 3..100
  validates_format_of   :email, :with => /^([^@\s]+)@((?:[-a-z0-9A-Z]+\.)+[a-zA-Z]{2,})$/
  validates_presence_of "state", :if => Proc.new{|x| x.american? }

  include Workflow
  workflow do
    state :new do
      event :profile_submitted, :transitions_to => :select_tier
      event :back, :transitions_to => :new
    end

    state :select_tier do
      event :tier_selected, :transitions_to => :enter_billing_information
      event :back, :transitions_to => :new
    end

    state :enter_billing_information do
      event :completed, :transitions_to => :complete
      event :back, :transitions_to => :select_tier
    end

    state :complete
  end

  def american?
    country == "United States"
  end

  def type_organization
    read_attribute("type_organization") || BUSINESS
  end

end
