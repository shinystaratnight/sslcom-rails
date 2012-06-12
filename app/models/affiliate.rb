class Affiliate < ActiveRecord::Base
  belongs_to  :ssl_account
  has_many    :line_items
  has_many    :orders, through: :line_items
  has_many    :visitor_tokens

  PROFILE_COLUMNS = %w(display_name tagline description)
  COMPANY_COLUMNS = %w(organization website address1 address2
    postal_code city state country contact_email contact_phone)
  ADMIN_COLUMNS = %w(first_name last_name email phone)
  PAYMENT_COLUMNS = %w(payout_threshold payout_method)
  EPASSPORTE_ACCOUNT = %w(epassporte_account)
  CHECKS_PAYABLE_TO = %w(checks_payable_to)
  BANK_COLUMNS = %w(bank_name bank_routing_number bank_account_number swift_code)
  REQUIRED_COLUMNS = %w(type_organization website address1 postal_code city
    state country contact_email contact_phone) + ADMIN_COLUMNS
  FORM_COLUMNS=%w(type_organization)+ADMIN_COLUMNS+COMPANY_COLUMNS+
    PAYMENT_COLUMNS
  #guarantee 10% profit on each sale
  ar=[]
  0.step((1-0.1-Settings.studio_fee_rate.to_f)*100,
    5){|i|ar<<i}
  AFFILIATE_PAYOUT_BRACKETS=ar.collect{|i| [i.to_s+"%",(i.to_f/100).to_s]}
  CHECK = "check"
  WIRE = "wired"
  EPASSPORTE = "epassporte"
  PAYPAL = "paypal"
  BUSINESS = "business"
  INDIVIDUAL = "individual"

  validates_presence_of *((REQUIRED_COLUMNS).map(&:intern))
  validates_presence_of *((BANK_COLUMNS).map(&:intern)+[:if => Proc.new{|affiliate| affiliate.payout_method == WIRE }])
  validates_presence_of :checks_payable_to, :if => Proc.new{|affiliate| affiliate.payout_method == CHECK }
  validates_presence_of :epassporte_account, :if => Proc.new{|affiliate| affiliate.payout_method == EPASSPORTE }
  #validates_presence_of :tax_number, :state, :if => Proc.new{|affiliate| affiliate.american? }
  validates_presence_of :organization, :if => Proc.new{|affiliate| affiliate.type_organization == BUSINESS }
  validates_length_of   *((FORM_COLUMNS+EPASSPORTE_ACCOUNT+
        CHECKS_PAYABLE_TO+BANK_COLUMNS).map(&:intern)+[:maximum => 100])
  #validates_length_of   :display_name, :maximum => 30
  #validates_uniqueness_of   :display_name, :case_sensitive=>false, :allow_nil=>true, :allow_blank=>true
  #validates_length_of   :tagline, :maximum => 60
  #validates_length_of   :description, :maximum => 500
  validates_length_of   :email,    :within => 3..100
  validates_format_of   :email, :with => /^([^@\s]+)@((?:[-a-z0-9A-Z]+\.)+[a-zA-Z]{2,})$/

  def american?
    country == "United States"
  end

  def payout_method
    read_attribute("payout_method") || CHECK
  end

  def payout_threshold
    read_attribute("payout_threshold") || "50"
  end

  def type_organization
    read_attribute("type_organization") || BUSINESS
  end

  def view_count
    self[:view_count] || 0
  end

  def display_name
    read_attribute(:display_name) || organization || "Studio"
  end

  def certificate_orders
    line_items.map(&:sellable).reject{|co|!co.is_a? CertificateOrder}
  end

end