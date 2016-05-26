class BillingProfile < ActiveRecord::Base  
  belongs_to  :ssl_account
  has_many    :orders
  include ActiveMerchant::Billing::CreditCardMethods

  cattr_accessor :password
  attr_accessor :number
  attr_encrypted :card_number, :key => '7ba44e6b-69d2-4d6d-889b-2872c0140092', :mode => :per_attribute_iv_and_salt

  ALL_COLUMNS = %w(description first_name last_name company address_1 address_2
    postal_code city state country phone vat credit_card card_number
    expiration_month expiration_year security_code last_digits data salt notes
    created_at updated_at)
  EXCLUDED_COLUMNS = %w(created_at updated_at description notes last_digits data salt)
  EXTENDED_FIELDS = %w(address_1 address_2)
  CREDIT_CARD_COLUMNS = %w(credit_card card_number security_code expiration_year expiration_month)
  BILLING_INFORMATION_COLUMNS = ALL_COLUMNS - EXCLUDED_COLUMNS - CREDIT_CARD_COLUMNS
  REQUIRED_COLUMNS = BILLING_INFORMATION_COLUMNS + CREDIT_CARD_COLUMNS - %w{address_2 company vat}
  TOP_COUNTRIES = ["United States", "United Kingdom", "Canada"]
  CREDIT_CARDS = ["Visa", "Master Card", "Discover", "American Express"]
  AMERICAN = "United States"

  # test - see http://developer.authorize.net/tools/errorgenerationguide/
  #TEST_ZIP_CODE = 46204
      #46282 #decline
  #TEST_AMOUNT = 70.02

  validates_presence_of *((REQUIRED_COLUMNS).map(&:intern))

  default_scope{ where{(status << ['disable']) | (status == nil)}}

  scope :success, lambda{
    joins{orders.transactions}.where{orders.transactions.success==true}
  }

  def verification_value?() false end
  
  def to_xml(options = {})
    super options.merge(:except => [:data, :salt])
  end

  def full_name
    first_name + " " + last_name
  end

  def masked_card_number
    mask = (0..(card_number.size - 8)).inject("") {|array,n|array << '*'}
    card_number.gsub(/(?<=\d{4})\d+(?=\d{4})/, mask)
  end

  def build_credit_card(options={})
    options.reverse_merge! cvv: true
    cc={    :first_name => options[:first_name] || first_name,
            :last_name  => options[:last_name] || last_name,
            :number     => options[:card_number] || card_number,
            :month      => options[:expiration_month] || expiration_month,
            :year       => options[:expiration_year] || expiration_year}
    cc.merge!(:verification_value => options[:verification_value] || security_code) if options[:cvv]
    card = ActiveMerchant::Billing::CreditCard.new(cc)
    card.type = 'bogus' if defined?(::GATEWAY_TEST_CODE)
    card
  end
  
  def build_address
    Address.new({
      :name         => self.full_name,
      :street1      => self.address_1,
      :street2      => self.address_2,
      :locality     => self.city,
      :region       => self.state,
      :country      => self.country,
      :postal_code  => (Rails.env=~/development/i && defined?(TEST_ZIP_CODE)) ? TEST_ZIP_CODE : self.postal_code, #testing decline or not
      :phone        => self.phone
    })
  end

  def build_info(description)
    {billing_address: self.build_address, description: description}
  end

  def american?
    country == AMERICAN
  end

  def expired?
    Date.new(expiration_year,expiration_month).end_of_month < Date.today
  end

  #if credit card is expired, provide two theoretical dates - incremented by 2 and 3 respectively
  def cycled_years
    unless expired?
      [expiration_year]
    else
      diff=((DateTime.now.to_i - DateTime.new(expiration_year, expiration_month).to_i)/1.year)
      [2,3].map do |i|
        v=diff/i
        #any reminders?
        expiration_year+((v.to_i + (v.is_a?(Integer) ? o : 1))*i)
      end
    end
  end

  def self.nullify_card_number_field
    self.find_each{|bp|bp.update_column(:card_number, nil)}
  end

  def self.encrypt_all_card_numbers
    self.find_each{|bp|bp.update_attribute(:card_number, bp.read_attribute(:card_number)) if
        bp.encrypted_card_number.blank?}
  end

  private

  before_create :store_last_digits

  def store_last_digits
    self.last_digits = self.class.last_digits(card_number)
  end
  
  def validate
    errors.add(:expiration_year, "is invalid" ) unless valid_expiry_year?(expiration_year)
    errors.add(:expiration_month, "is invalid" ) unless valid_month?(expiration_month)
    errors.add(:card_number, "is invalid" ) unless self.class.valid_number?(card_number)
    if password.blank?
      errors[:base] << "Unable to encrypt or decrypt data without password"
    end
  end
end