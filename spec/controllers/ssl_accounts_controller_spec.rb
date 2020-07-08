require 'rails_helper'

describe SslAccountsController do
  include SessionHelper
  let!(:ssl_account) { create(:ssl_account, sec_type: nil) }
  let!(:user) { create(:user, :account_admin, default_ssl_account: ssl_account.id, ssl_accounts: [ssl_account]) }

  before do
    activate_authlogic
    login_as(user)
  end

  describe '#update_settings' do
    before do
      put :update_settings, { ssl_account: { preferred_processed_include_cert_admin: '1' },
                              ssl_slug: user.ssl_account.acct_number }
      ssl_account.reload
    end

    it 'changes sec_type' do
      expect(ssl_account.preferences['processed_include_cert_admin']).to eq 't'
    end

    it 'shows flash message' do
      expect(flash[:notice].present?).to eq true
    end

    it 'executes successfully' do
      expect(response.code).to eq '302'
    end
  end
end
