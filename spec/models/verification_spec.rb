require 'rails_helper'

describe Verification, type: :model do
  describe 'validations' do
    let(:user) { create(:user) }
    let(:verification) { build(:all_verifications, user: user) }

    it 'is valid' do
      expect(verification).to be_valid
    end

    it 'require phone_prefix for call' do
      call_verification = build(:call_verification, call_prefix: nil)
      expect(call_verification).to_not be_valid
    end

    it 'require phone_prefix for sms' do
      sms_verification = build(:sms_verification, sms_prefix: nil)
      expect(sms_verification).to_not be_valid
    end

    it 'requires email for email verification' do
      email_verification = build(:email_verification, email: nil)
      expect(email_verification.sms_number).to eq nil
      expect(email_verification).to_not be_valid
    end
  end
end
