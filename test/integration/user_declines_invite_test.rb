require 'test_helper'
# 
# Existing user declines invite to an ssl account.
# 
describe 'Decline ssl account invite' do
  before do
    create_reminder_triggers
    create_roles
    set_common_roles
    @existing_user_email = 'exist_user@domain.com'
    @current_admin       = create(:user, :account_admin)
    @existing_user       = create(:user, :account_admin, email: @existing_user_email)
    @invited_ssl_acct    = @current_admin.ssl_account
    @existing_user_ssl   = @existing_user.ssl_account
    
    @existing_user.activate!(
      user: {login: 'existing_user', password: 'testing', password_confirmation: 'testing'}
    )

    login_as(@current_admin, self.controller.cookies)
    visit account_path
    click_on 'Users'
    click_on '+ Create User'
    fill_in  'user_email', with: @existing_user_email
    find('input[value="Invite"]').click
    
    click_on 'Logout'
    login_as(@existing_user, update_cookie(self.controller.cookies, @existing_user))
    visit account_path
  end
  
  describe 'BEFORE Decline' do
    it 'can only see their own account' do
      ssl = @existing_user.ssl_account_users.find_by(ssl_account_id: @invited_ssl_acct.id)
      assert page.has_no_content? 'ACCOUNT'
      assert_equal 2, @existing_user.ssl_accounts.count
      assert_equal 2, @existing_user.roles.count
      # only invited user's own account is approved
      assert_equal 1, @existing_user.get_all_approved_accounts.count
      # invited account has expiring approval token
      refute_nil   ssl.approval_token
      refute_nil   ssl.token_expires
      refute       ssl.approved
    end
    it 'can see flash notice to accept or reject invitation' do
      page.must_have_content "You have been invited to join account ##{@invited_ssl_acct.acct_number}.
        Please click here to accept the invitation. Click decline to reject."
    end
  end

  describe 'AFTER Decline' do
    before do
      # has one invite to ssl account
      assert_equal 1, @existing_user.get_pending_accounts.count 
      assert          @existing_user.pending_account_invites?

      find('a', text: 'decline').click
    end
    
    it 'account invite should be declined' do
      params = {ssl_account_id: @invited_ssl_acct.id}
      ssl    = @existing_user.ssl_account_users.find_by(params)
      
      assert       page.has_no_content? 'ACCOUNT'
      assert       @existing_user.user_declined_invite?(params)
      assert_equal @existing_user_ssl.id, @existing_user.default_ssl_account
      assert_nil   ssl.approval_token
      assert_nil   ssl.token_expires
      refute       ssl.approved
    end
    it 'has 1 approved account | 0 pending invites' do
      assert_equal 1, @existing_user.get_all_approved_accounts.count
      assert_equal 0, @existing_user.get_pending_accounts.count
      refute          @existing_user.pending_account_invites?
    end
    it 'account_admin should see decline status' do
      click_on 'Logout'
      login_as(@current_admin, self.controller.cookies)
      visit account_path
      click_on 'Users'

      page.must_have_content 'declined'
    end
    it 'sysadmin should see decline status' do
      sysadmin = create(:user, :sysadmin)
      click_on 'Logout'
      login_as(sysadmin, update_cookie(self.controller.cookies, sysadmin))
      visit account_path
      click_on 'Users'
      first('td', text: @existing_user_email).click # expand user's row
      
      page.must_have_content("##{@invited_ssl_acct.acct_number.upcase}: declined")
    end

  end
end
