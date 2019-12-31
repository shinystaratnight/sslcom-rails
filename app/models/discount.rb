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
