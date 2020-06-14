# == Schema Information
#
# Table name: invoices
#
#  id               :integer          not null, primary key
#  address_1        :string(255)
#  address_2        :string(255)
#  billable_type    :string(255)
#  city             :string(255)
#  company          :string(255)
#  country          :string(255)
#  default_payment  :string(255)
#  description      :text(65535)
#  end_date         :datetime
#  fax              :string(255)
#  first_name       :string(255)
#  last_name        :string(255)
#  notes            :text(65535)
#  phone            :string(255)
#  postal_code      :string(255)
#  reference_number :string(255)
#  start_date       :datetime
#  state            :string(255)
#  status           :string(255)
#  tax              :string(255)
#  type             :string(255)
#  vat              :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  billable_id      :integer
#  order_id         :integer
#
# Indexes
#
#  index_invoices_on_billable_id_and_billable_type  (billable_id,billable_type)
#  index_invoices_on_id_and_type                    (id,type)
#  index_invoices_on_order_id                       (order_id)
#

FactoryBot.define do
  factory :invoice do
    address_1   { Faker::Address.street_address }
    city        { Faker::Address.city }
    country     { Faker::Address.country }
    description { Faker::Lorem.sentence }

    first_name  { Faker::Name.first_name }
    last_name   { Faker::Name.last_name }
    postal_code { Faker::Address.zip_code }

    state       { 'pending' }
  end
end
