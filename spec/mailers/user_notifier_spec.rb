require 'rails_helper'

RSpec.describe UserNotifier, type: :mailer do
  let(:user) { create(:user, :owner) }

  describe 'auto_activation_confirmation' do
    let(:mail) { described_class.auto_activation_confirmation(user) }

    it 'send mail to user\'s email' do
      expect(mail.to).to include(user.email)
    end

    it 'sets subject to SSL.com user account auto activated' do
      expect(mail.subject).to eq('SSL.com user account auto activated')
    end

    it 'includes community name correctly' do
      expect(mail.body.encoded).to include("Your #{Settings.community_name} account for username #{user.login} has been auto activated.")
    end

    it 'links to ssl_account' do
      expect(mail.body.encoded).to include("#{Settings.domain}/account")
    end

    it 'includes support content' do
      expect(mail.body.encoded).to include(Settings.corp_tollfree_tag)
    end
  end
end
