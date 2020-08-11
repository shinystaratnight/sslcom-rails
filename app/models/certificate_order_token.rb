# == Schema Information
#
# Table name: certificate_order_tokens
#
#  id                       :integer          not null, primary key
#  callback_datetime        :datetime
#  callback_method          :string(255)
#  callback_timezone        :string(255)
#  callback_type            :string(255)
#  due_date                 :datetime
#  is_callback_done         :boolean
#  is_expired               :boolean
#  locale                   :string(255)
#  passed_token             :string(255)
#  phone_call_count         :integer
#  phone_number             :string(255)
#  phone_verification_count :integer
#  status                   :string(255)
#  token                    :string(255)
#  created_at               :datetime
#  updated_at               :datetime
#  certificate_order_id     :integer
#  ssl_account_id           :integer
#  user_id                  :integer
#
# Indexes
#
#  index_certificate_order_tokens_on_certificate_order_id  (certificate_order_id)
#  index_certificate_order_tokens_on_ssl_account_id        (ssl_account_id)
#  index_certificate_order_tokens_on_user_id               (user_id)
#

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
