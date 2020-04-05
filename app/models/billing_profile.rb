# frozen_string_literal: false

# == Schema Information
#
# Table name: billing_profiles
#
#  id                         :integer          not null, primary key
#  address_1                  :string(255)
#  address_2                  :string(255)
#  card_number                :string(255)
#  city                       :string(255)
#  company                    :string(255)
#  country                    :string(255)
#  credit_card                :string(255)
#  data                       :binary(65535)
#  default_profile            :boolean
#  description                :string(255)
#  encrypted_card_number      :string(255)
#  encrypted_card_number_iv   :string(255)
#  encrypted_card_number_salt :string(255)
#  expiration_month           :integer
#  expiration_year            :integer
#  first_name                 :string(255)
#  last_digits                :string(255)
#  last_name                  :string(255)
#  notes                      :string(255)
#  phone                      :string(255)
#  postal_code                :string(255)
#  salt                       :binary(65535)
#  security_code              :string(255)
#  state                      :string(255)
#  status                     :string(255)
#  tax                        :string(255)
#  vat                        :string(255)
#  created_at                 :datetime
#  updated_at                 :datetime
#  ssl_account_id             :integer
#
# Indexes
#
#  index_billing_profile_on_ssl_account_id  (ssl_account_id)
#

class BillingProfile < ApplicationRecord
  include ActiveMerchant::Billing::CreditCardMethods

  belongs_to  :ssl_account
  has_many    :orders, -> { unscope(where: [:state]) }

  before_create :store_last_digits
  after_save    :set_one_default

  cattr_accessor :password
  attr_accessor  :number, :stripe_card_token
  attr_encrypted :card_number, key: 'v1X&3az00c!F', algorithm: 'aes-256-cbc', mode: :per_attribute_iv_and_salt, insecure_mode: true

  ALL_COLUMNS = %w[description first_name last_name company address_1 address_2 postal_code city state country phone vat credit_card 
                   card_number expiration_month expiration_year security_code last_digits data salt notes created_at updated_at].freeze
  EXCLUDED_COLUMNS = %w[created_at updated_at description notes last_digits data salt].freeze
  EXTENDED_FIELDS = %w[address_1 address_2].freeze
  CREDIT_CARD_COLUMNS = %w[credit_card card_number security_code expiration_year expiration_month].freeze
  BILLING_INFORMATION_COLUMNS = ALL_COLUMNS - EXCLUDED_COLUMNS - CREDIT_CARD_COLUMNS
  REQUIRED_COLUMNS = BILLING_INFORMATION_COLUMNS + CREDIT_CARD_COLUMNS - %w[address_2 company vat]
  TOP_COUNTRIES = ['United States', 'United Kingdom', 'Canada'].freeze
  CREDIT_CARDS = ['Visa', 'Master Card', 'Discover', 'American Express'].freeze
  AMERICAN = 'United States'

  GATEWAY = ENV['GATEWAY']
  # test - see http://developer.authorize.net/tools/errorgenerationguide/
  # TEST_ZIP_CODE = 46204 #46282 #decline
  TEST_AMOUNT = 80.50 # valid
  # TEST_AMOUNT = 70.02 # This transaction has been declined.

  validates_presence_of *REQUIRED_COLUMNS.map(&:intern)

  default_scope{ where{ (status << ['disable']) | (status == nil) } }

  scope :success, lambda{
    joins{ orders.transactions }.where{ orders.transactions.success == true }
  }

  scope :search, lambda { |term|
    joins{ orders }.where do
      (first_name =~ "%#{term}%") |
        (last_name =~ "%#{term}%") |
        (address_1 =~ "%#{term}%") |
        (address_2 =~ "%#{term}%") |
        (country =~ "%#{term}%") |
        (city =~ "%#{term}%") |
        (state =~ "%#{term}%") |
        (postal_code =~ "%#{term}%") |
        (phone =~ "%#{term}%") |
        (company =~ "%#{term}%") |
        (last_digits =~ "%#{term}%") |
        (orders.reference_number =~ "%#{term}%")
    end
  }

  def verification_value?
    false
  end

  def to_xml(options = {})
    super options.merge(except: %i[data salt])
  end

  def full_name
    first_name + ' ' + last_name
  end

  def masked_card_number
    card = card_number.gsub(/\s+/, '')
    mask = (0..(card.size - 8)).inject('') { |array, _n| array << '*' }
    card.gsub(/(?<=\d{4})\d+(?=\d{4})/, mask)
  end

  def build_credit_card(options = {})
    options.reverse_merge! cvv: true
    cc = { first_name: options[:first_name] || first_name,
           last_name: options[:last_name] || last_name,
           number: options[:card_number] || card_number,
           month: options[:expiration_month] || expiration_month,
           year: options[:expiration_year] || expiration_year }
    cc.merge!(verification_value: options[:verification_value] || security_code) if options[:cvv]
    card = ActiveMerchant::Billing::CreditCard.new(cc)
    card.brand = 'bogus' if defined?(::GATEWAY_TEST_CODE)
    card
  end

  def build_address
    Address.new(
      name: full_name,
      street1: address_1,
      street2: address_2,
      locality: city,
      region: state,
      country: country,
      postal_code: %w[development test].include?(Rails.env) && defined?(TEST_ZIP_CODE) ? TEST_ZIP_CODE : postal_code, # testing decline or not
      phone: phone
    )
  end

  def build_info(description)
    { billing_address: build_address, description: description }
  end

  def american?
    country == AMERICAN
  end

  def expired?
    Date.new(expiration_year, expiration_month).end_of_month < Time.zone.today
  end

  # if credit card is expired, provide two theoretical dates - incremented by 2 and 3 respectively
  def cycled_years
    if expired?
      diff = ((DateTime.now.to_i - DateTime.new(expiration_year, expiration_month).to_i) / 1.year)
      [2, 3].map do |i|
        v = diff / i
        # any reminders?
        expiration_year + ((v.to_i + (v.is_a?(Integer) ? o : 1)) * i)
      end
    else
      [expiration_year]
    end
  end

  def self.nullify_card_number_field
    find_each{ |bp| bp.update_column(:card_number, nil) }
  end

  def self.encrypt_all_card_numbers
    find_each{ |bp| bp.update_attribute(:card_number, bp.read_attribute(:card_number)) if bp.encrypted_card_number.blank? }
  end

  def self.gateway_stripe?
    GATEWAY == 'stripe'
  end

  def self.anet_public_keys
    # public keys that can be displayed and used with Authorize.net Accept.js
    {
      client_key: Rails.application.secrets.authorize_net_client_key,
      api_login_id: Rails.application.secrets.authorize_net_key
    }
  end

  def users_can_manage
    Assignment.where(
      ssl_account_id: ssl_account.id, role_id: Role.can_manage_billing
    ).map(&:user).uniq
  end

  private

  def default_profile_exists?
    ssl_account.billing_profiles.where(default_profile: true).any?
  end

  def set_one_default
    if default_profile
      ssl_account.billing_profiles
                 .where(default_profile: true).where.not(id: id)
                 .update_all(default_profile: false)
    else
      update(default_profile: true) unless default_profile_exists?
    end
  end

  def store_last_digits
    self.last_digits = self.class.last_digits(card_number)
  end

  def validate
    validate_expiration_year
    validate_expiration_month
    validate_card_number
    validate_password_presences
  end

  def validate_expiration_year
    errors.add(:expiration_year, 'is invalid') unless valid_expiry_year?(expiration_year)
  end

  def validate_expiration_month
    errors.add(:expiration_month, 'is invalid') unless valid_month?(expiration_month)
  end

  def validate_card_number
    errors.add(:card_number, 'is invalid') unless self.class.valid_number?(card_number)
  end

  def validate_password_presences
    errors[:base] << 'Unable to encrypt or decrypt data without password' if password.blank?
  end
end
