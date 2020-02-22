# == Schema Information
#
# Table name: discounts
#
#  id                :integer          not null, primary key
#  apply_as          :string(255)
#  benefactor_type   :string(255)
#  discountable_type :string(255)
#  expires_at        :datetime
#  label             :string(255)
#  ref               :string(255)
#  remaining         :integer
#  status            :string(255)
#  value             :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  benefactor_id     :integer
#  discountable_id   :integer
#
# Indexes
#
#  index_discounts_on_benefactor_id_and_benefactor_type  (benefactor_id,benefactor_type)
#  index_discounts_on_discountable_id                    (discountable_id)
#

class Discount < ApplicationRecord
  has_and_belongs_to_many :certificates
  has_and_belongs_to_many :orders
  belongs_to :benefactor, polymorphic: true

  APPLY_AS = [:percentage, :absolute]

  #this used to be the default scopr but upgrading to Rails 4.2 'broke' it
  scope :viable, ->{where{(status >> [nil, 'active']) & ((remaining > 0) | (remaining >> [nil])) &
      ((expires_at >> [nil]) | (expires_at >= Date.today))}}

  scope :general, ->{where{((benefactor_id==nil) & (benefactor_type==nil))}}

  scope :include_all, lambda {Discount.unscoped}
end
