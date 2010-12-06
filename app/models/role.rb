class Role < ActiveRecord::Base
  has_many :assignments
  has_many :users, :through => :assignments

  RESELLER = 'reseller'
  CUSTOMER = 'customer'
  VETTER = 'vetter'
end
