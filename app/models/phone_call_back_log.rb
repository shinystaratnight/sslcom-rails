# == Schema Information
#
# Table name: phone_call_back_logs
#
#  id                   :integer          not null, primary key
#  cert_order_ref       :string(255)      not null
#  phone_number         :string(255)      not null
#  validated_at         :datetime         not null
#  validated_by         :string(255)      not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  certificate_order_id :integer
#
# Indexes
#
#  fk_phone_call_back_logs_certificate_order_id  (certificate_order_id)
#
# Foreign Keys
#
#  fk_phone_call_back_logs_certificate_order_id  (certificate_order_id => certificate_orders.id) ON DELETE => restrict ON UPDATE => restrict
#
class PhoneCallBackLog < ActiveRecord::Base
  validates :validated_by, presence: true
  validates :cert_order_ref, presence: true
  validates :phone_number, presence: true
  validates :validated_at, presence: true
  belongs_to :certificate_order
end
