class CertificateOrderToken < ActiveRecord::Base
  belongs_to :certificate_order
  belongs_to :ssl_account
  belongs_to :user

  DONE_STATUS = 'done'
  PENDING_STATUS = 'pending'
end