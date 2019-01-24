class CertificateOrderToken < ActiveRecord::Base
  belongs_to :certificate_order
  belongs_to :ssl_account
  belongs_to :user

  PENDING_STATUS = 'pending'
  EXPIRED_STATUS = 'expired'
  FAILED_STATUS = 'failed'
  DONE_STATUS = 'done'
  PHONE_VERIFICATION_LIMIT_MAX_COUNT = 3
  PHONE_CALL_LIMIT_MAX_COUNT = 3
end