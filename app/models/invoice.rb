class Invoice < ActiveRecord::Base
  
  validates :first_name, :last_name, :address_1, :country, :city, 
    :state, :postal_code, presence: true
end