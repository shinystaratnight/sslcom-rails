require 'test_helper'

class SslAccountTest < Minitest::Spec

  before do
    create_reminder_triggers
  end

  describe 'attributes' do
    before(:each)  { @ssl_acct = create(:ssl_account) }

    it { assert_respond_to @ssl_acct, :acct_number }
    it { assert_respond_to @ssl_acct, :roles }
    it { assert_respond_to @ssl_acct, :status }
    it { assert_respond_to @ssl_acct, :ssl_slug }
    it { assert_respond_to @ssl_acct, :company_name }
  end

  describe 'validations' do
  end

  describe 'slug string validation' do
    it '#ssl_slug_valid? string "company" should be valid' do
      assert SslAccount.ssl_slug_valid?('company')
    end
    it '#ssl_slug_valid? string w/underscore should be valid' do
      assert SslAccount.ssl_slug_valid?('company_1')
    end
    it '#ssl_slug_valid? string w/dash should be valid' do
      assert SslAccount.ssl_slug_valid?('company-1')
    end
    it '#ssl_slug_valid? string w/digits should be valid' do
      assert SslAccount.ssl_slug_valid?('20160102')
    end
    it '#ssl_slug_valid? string using symbols should NOT be valid' do
      (%w{ ~ ! @ # $ % ^ & * ( ) = ` < > ? . , | [ ] / ; : ' "} + ['{', '}']).each do |symbol|
        refute SslAccount.ssl_slug_valid?("team_#{symbol}")
      end
    end
    it '#ssl_slug_valid? string using route names should NOT be valid' do
      %w{ oauth_clients managed_users user_session }.each do |named_route|
        refute SslAccount.ssl_slug_valid?(named_route)
      end
    end
  end

  describe 'helper methods' do
    before { initialize_roles }
    it '#get_account_owner returns correct user/owner' do
      target_user = create(:user, :account_admin)
      target_ssl  = target_user.ssl_account
      other_user  = create_and_approve_user(target_ssl, 'other_user')
      
      assert_equal target_user, target_ssl.get_account_owner
      refute_equal other_user, target_ssl.get_account_owner
    end
  end
end
