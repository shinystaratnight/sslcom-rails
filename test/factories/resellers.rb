# frozen_string_literal: true

# == Schema Information
#
# Table name: resellers
#
#  id                :integer          not null, primary key
#  ssl_account_id    :integer
#  reseller_tier_id  :integer
#  first_name        :string(255)
#  last_name         :string(255)
#  email             :string(255)
#  phone             :string(255)
#  organization      :string(255)
#  address1          :string(255)
#  address2          :string(255)
#  address3          :string(255)
#  po_box            :string(255)
#  postal_code       :string(255)
#  city              :string(255)
#  state             :string(255)
#  country           :string(255)
#  ext               :string(255)
#  fax               :string(255)
#  website           :string(255)
#  tax_number        :string(255)
#  roles             :string(255)
#  type_organization :string(255)
#  workflow_state    :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#

FactoryBot.define do
  factory :reseller do
    ssl_account
    website { Faker::Internet.domain_name }
    address1 { Faker::Address.street_address }
    postal_code { Faker::Address.zip_code }
    city { Faker::Address.city }
    country { Faker::Address.country }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    phone { Faker::PhoneNumber.cell_phone }
    email { Faker::Internet.email }
    organization { Faker::Company.name }
  end
end
