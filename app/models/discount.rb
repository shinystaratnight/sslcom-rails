class Discount < ActiveRecord::Base
  has_and_belongs_to_many :certificates
  has_and_belongs_to_many :orders
  APPLY_AS = [:percentage, :absolute]

  #this used to be the default scope but upgrading to Rails 4.2 'broke' it
  scope :viable, ->(benefactor=nil){
    id, type = benefactor.blank? ? [nil,nil] : [benefactor.id, benefactor.class.to_s]
    where{(status >> [nil, 'active']) & ((remaining > 0) | (remaining >> [nil])) &
      ((expires_at >> [nil]) | (expires_at >= Date.today)) & ((benefactor_id==id) &
        (benefactor_type==type))}
  }

  scope :include_all, lambda {Discount.unscoped}
end
