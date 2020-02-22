# == Schema Information
#
# Table name: csr_overrides
#
#  id                :integer          not null, primary key
#  address_1         :string(255)
#  address_2         :string(255)
#  address_3         :string(255)
#  common_name       :string(255)
#  country           :string(255)
#  locality          :string(255)
#  organization      :string(255)
#  organization_unit :string(255)
#  po_box            :string(255)
#  postal_code       :string(255)
#  state             :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  csr_id            :integer
#
# Indexes
#
#  index_csr_overrides_on_csr_id  (csr_id)
#

class CsrOverride < ApplicationRecord
  belongs_to  :csr
end
