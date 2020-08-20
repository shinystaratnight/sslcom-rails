class CertificateOrderToken < ApplicationRecord
  belongs_to :certificate_order
  belongs_to :ssl_account
  belongs_to :user

  PENDING_STATUS = 'pending'
  EXPIRED_STATUS = 'expired'
  FAILED_STATUS = 'failed'
  DONE_STATUS = 'done'
  PHONE_VERIFICATION_LIMIT_MAX_COUNT = 3
  PHONE_CALL_LIMIT_MAX_COUNT = 3
  CALLBACK_SCHEDULE = 'schedule'
  CALLBACK_MANUAL = 'manual'

  scope :scheduled_callback, -> {
    where{(status == PENDING_STATUS) &
        (callback_type == CALLBACK_SCHEDULE) &
        (is_callback_done == false) &
        (callback_datetime <= DateTime.current())
    }
  }
end
