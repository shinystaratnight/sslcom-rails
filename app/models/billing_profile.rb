class BillingProfile < ActiveRecord::Base  
  belongs_to  :ssl_account
  has_many    :orders
  include Encryption, ActiveMerchant::Billing::CreditCardMethods

  cattr_accessor :password
  attr_accessor :number

  ALL_COLUMNS = %w(description first_name last_name address_1 address_2
    postal_code city state country phone company credit_card card_number
    expiration_month expiration_year security_code last_digits data salt notes
    created_at updated_at)
  EXCLUDED_COLUMNS = %w(created_at updated_at description
    notes last_digits data salt company)
  EXTENDED_FIELDS = %w(address_1 address_2)
  CREDIT_CARD_COLUMNS = %w(credit_card card_number security_code expiration_year expiration_month)
  BILLING_INFORMATION_COLUMNS = ALL_COLUMNS - EXCLUDED_COLUMNS - CREDIT_CARD_COLUMNS
  REQUIRED_COLUMNS = BILLING_INFORMATION_COLUMNS + CREDIT_CARD_COLUMNS - %w{address_2 company}
  TOP_COUNTRIES = ["United States", "United Kingdom", "Canada"]
  CREDIT_CARDS = ["Visa", "Master Card", "Discover", "American Express"]
  AMERICAN = "United States"

  validates_presence_of *((REQUIRED_COLUMNS).map(&:intern))

  scope :success, lambda{
    joins({:orders=>:order_transactions}).where({:orders=>{:order_transactions=>[:success => true]}})
  }

  def verification_value?() false end
  
  def to_xml(options = {})
    super options.merge(:except => [:data, :salt])
  end
  
  def encrypt_number
    self.data = encrypt(card_number, password, salt)
  end
  
  def decrypt_number
    self.card_number = decrypt(data, password, salt)
  end
  
  def full_name
    first_name + " " + last_name
  end

  def masked_card_number
    mask = (0..(card_number.size - 8)).inject("") {|array,n|array << '*'}
    card_number.gsub(/(?<=\d{4})\d+(?=\d{4})/, mask)
  end

  def american?
    country == AMERICAN
  end
  
  private
  
  before_create :store_last_digits, :generate_salt, :encrypt_number
  
  def store_last_digits
    self.last_digits = self.class.last_digits(card_number)
  end
  
  def generate_salt
    self.salt = [rand(2**64 - 1)].pack("Q" )
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