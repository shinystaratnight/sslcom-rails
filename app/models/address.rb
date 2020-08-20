class Address < ApplicationRecord
  ADDRESS_MAPPING = { address1: :street1, address2: :street2, city: :locality, state: :region, zip: :postal_code }

  def read_attribute_with_mapping(attr_name)
    read_attribute_without_mapping(ADDRESS_MAPPING[attr_name] || attr_name)
  end
  alias_method_chain :read_attribute, :mapping
end
