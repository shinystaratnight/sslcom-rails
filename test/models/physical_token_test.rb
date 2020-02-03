# == Schema Information
#
# Table name: physical_tokens
#
#  id                    :integer          not null, primary key
#  certificate_order_id  :integer
#  signed_certificate_id :integer
#  tracking_number       :string(255)
#  shipping_method       :string(255)
#  activation_pin        :string(255)
#  manufacturer          :string(255)
#  model_number          :string(255)
#  serial_number         :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  notes                 :text(65535)
#  name                  :string(255)
#  workflow_state        :string(255)
#  admin_pin             :string(255)
#  license               :string(255)
#  management_key        :string(255)
#

require "test_helper"

describe PhysicalToken do
  let(:physical_token) { PhysicalToken.new }

  it "must be valid" do
    value(physical_token).must_be :valid?
  end
end
