class Discount < ActiveRecord::Base
  has_and_belongs_to_many :certificates
  has_and_belongs_to_many :orders
  APPLY_AS = [:percentage, :absolute]

  default_scope{ where{(status >> [nil, 'active']) & ((remaining > 0) | (remaining >> [nil])) &}
      ((expires_at >> [nil]) | (expires_at >= Date.today))}

  scope :include_all, lambda {Discount.unscoped}
end
