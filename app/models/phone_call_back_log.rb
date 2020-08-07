class PhoneCallBackLog < ActiveRecord::Base
  validates :validated_by, presence: true
  validates :cert_order_ref, presence: true
  validates :phone_number, presence: true
  validates :validated_at, presence: true
  belongs_to :certificate_order
end
