require 'rails_helper'

RSpec.describe OrderNotifier, type: :mailer do
  let(:audit) { create(:system_audit) }

  describe 'problem' do
    let(:mail) { described_class.problem(audit) }

    it 'sends to support email' do
      expect(mail.to).to include('support@ssl.com')
    end

    it 'sets subject to A problem has been detected' do
      expect(mail.subject).to eq('A problem has been detected')
    end

    it 'identifies the owner' do
      expect(mail.body.encoded).to include('Owner: user_')
    end

    it 'identifies the target' do
      expect(mail.body.encoded).to include('Target: certificate_')
    end
  end
end
