class CertificateOrderToken < ActiveRecord::Base
  belongs_to :certificate_order
  belongs_to :ssl_account
  belongs_to :user
end