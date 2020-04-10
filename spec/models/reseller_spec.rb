# == Schema Information
#
# Table name: resellers
#
#  id                :integer          not null, primary key
#  address1          :string(255)
#  address2          :string(255)
#  address3          :string(255)
#  city              :string(255)
#  country           :string(255)
#  email             :string(255)
#  ext               :string(255)
#  fax               :string(255)
#  first_name        :string(255)
#  last_name         :string(255)
#  organization      :string(255)
#  phone             :string(255)
#  po_box            :string(255)
#  postal_code       :string(255)
#  roles             :string(255)
#  state             :string(255)
#  tax_number        :string(255)
#  type_organization :string(255)
#  website           :string(255)
#  workflow_state    :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  reseller_tier_id  :integer
#  ssl_account_id    :integer
#
# Indexes
#
#  index_resellers_on_reseller_tier_id  (reseller_tier_id)
#  index_resellers_on_ssl_account_id    (ssl_account_id)
#
require 'rails_helper'

RSpec.describe Reseller, type: :model do
  it_behaves_like 'it has roles'
end
