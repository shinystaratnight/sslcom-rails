# == Schema Information
#
# Table name: physical_tokens
#
#  id                    :integer          not null, primary key
#  activation_pin        :string(255)
#  admin_pin             :string(255)
#  license               :string(255)
#  management_key        :string(255)
#  manufacturer          :string(255)
#  model_number          :string(255)
#  name                  :string(255)
#  notes                 :text(65535)
#  serial_number         :string(255)
#  shipping_method       :string(255)
#  tracking_number       :string(255)
#  workflow_state        :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  certificate_order_id  :integer
#  signed_certificate_id :integer
#
# Indexes
#
#  index_physical_tokens_on_certificate_order_id   (certificate_order_id)
#  index_physical_tokens_on_signed_certificate_id  (signed_certificate_id)
#

FactoryBot.define do
  factory :physical_token do
    workflow_state { 'received' }
  end
end
