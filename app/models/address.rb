# == Schema Information
#
# Table name: addresses
#
#  id          :integer          not null, primary key
#  country     :string(255)
#  locality    :string(255)
#  name        :string(255)
#  phone       :string(255)
#  postal_code :string(255)
#  region      :string(255)
#  street1     :string(255)
#  street2     :string(255)
#

class Address < ApplicationRecord
  ADDRESS_MAPPING  = { :address1 => :street1, :address2 => :street2,
    :city => :locality, :state => :region, :zip => :postal_code }
  
  def read_attribute_with_mapping(attr_name)
    read_attribute_without_mapping(ADDRESS_MAPPING[attr_name] || attr_name)
  end
  alias_method_chain :read_attribute, :mapping
  
end
