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
require 'rails_helper'

describe PhoneCallBackLog, type: :model do
  subject { described_class.new(
    validated_by: Faker::Internet.username(specifier: 8..15),
    cert_order_ref: "co-#{Faker::Alphanumeric.alphanumeric(number: 12)}",
    phone_number: Faker::PhoneNumber.phone_number_with_country_code,
    validated_at: DateTime.now)
  }

  it 'is valid' do
    expect(subject).to be_valid
  end

  it 'is not valid without validated_by' do
    subject.validated_by = nil
    expect(subject).to_not be_valid
  end

  it 'is not valid without cert_order_ref' do
    subject.cert_order_ref = nil
    expect(subject).to_not be_valid
  end

  it 'is not valid without a phone_number' do
    subject.phone_number = nil
    expect(subject).to_not be_valid
  end

  it 'is not validated without a validated_at timestamp' do
    subject.validated_at = nil
    expect(subject).to_not be_valid
  end
end
