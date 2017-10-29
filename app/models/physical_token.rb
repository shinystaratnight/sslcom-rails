class PhysicalToken < ActiveRecord::Base
  belongs_to :certificate_order
  belongs_to :signed_certificate
end