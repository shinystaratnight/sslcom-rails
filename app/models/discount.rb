class Discount < ActiveRecord::Base
  has_and_belongs_to_many :certificates
  has_and_belongs_to_many :orders
  APPLY_AS = [:percentage, :absolute]

  default_scope where{(status >> [nil, 'active']) & ((uses <= 0) | (uses >> [nil])) &
      ((expires_at >> [nil]) | (expires_at >= Date.today))}
end
