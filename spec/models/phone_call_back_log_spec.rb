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
