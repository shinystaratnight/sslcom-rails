class ApiCreditCard
  include ActiveModel::Validations
  include ActiveModel::Serialization

  # attr_accessor :first_name, :last_name, :number, :expires, :cvv, :street_address_1,
  #   :street_address_2, :street_address_3, :post_office_box, :locality, :state_or_province, :postal_code, :country
  #
  validates_presence_of :first_name, :last_name, :number, :expires, :cvv, :street_address_1, :locality,
    :state_or_province, :postal_code, :country

  attr_accessor :attributes
  def initialize(attributes = {})
    @attributes = attributes
  end

  def read_attribute_for_validation(key)
    @attributes[key]
  end
end