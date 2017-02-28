require 'test_helper'
# 
# Only existing SSL.com user can receive account invite with approval token.
# 
describe 'user approves ssl account invite' do
  before do
    initialize_roles
    @existing_user_email = 'exist_user@domain.com'
    @current_owner       = create(:user, :owner)
    @existing_user       = create(:user, :owner, email: @existing_user_email)
    @unauthorized_user   = create(:user, :owner)
    @invited_ssl_acct    = @current_owner.ssl_account
    @existing_user_ssl   = @existing_user.ssl_account
    
    @existing_user.activate!(
      user: {login: 'existing_user', password: 'testing', password_confirmation: 'testing'}
    )

    login_as(@current_owner, self.controller.cookies)
    visit account_path
    click_on 'Users'
    click_on 'Invite User'
    fill_in  'user_email', with: @existing_user_email
    find('input[value="Invite"]').click
    sleep 1 # allow time to generate notification email
  end

  describe 'BEFORE Approved: invited user' do
    it 'can only see their own account' do
      click_on 'Logout'
      login_as(@existing_user, update_cookie(self.controller.cookies, @existing_user))
      visit account_path

      assert page.has_content? 'Teams(1)'
      assert_equal 2, @existing_user.ssl_accounts.count
      assert_equal 2, @existing_user.roles.count
      # only invited user's own account is approved
      assert_equal 1, @existing_user.get_all_approved_accounts.count
      # invited account has expiring approval token
      ssl = SslAccountUser.where(
        ssl_account_id: @invited_ssl_acct.id, user_id: @existing_user.id
      ).first
      refute_nil   ssl.approval_token
      refute_nil   ssl.token_expires
      refute       ssl.approved
    end
  end

  describe 'AFTER Approved: invited user' do
    before do
      click_on 'Logout'
      login_as(@existing_user, update_cookie(self.controller.cookies, @existing_user))
      email_approval_link = extract_url(email_body(:first))
      visit email_approval_link
    end
    
    it 'can see both accounts' do
      assert       page.has_content? 'Teams(2)'
      assert       page.has_content? 'Users'
      assert       page.has_content? @existing_user_ssl.acct_number.upcase
      assert_equal 2, @existing_user.get_all_approved_accounts.count
    end
    it 'can switch to invited ssl account' do
      find('div.acc-sel-dropbtn').click # CURRENT TEAM dropdown
      find('a', text: @invited_ssl_acct.acct_number.upcase).click
      ssl = SslAccountUser.where(
        ssl_account_id: @invited_ssl_acct.id, user_id: @existing_user.id
      ).first
      assert_equal @invited_ssl_acct.id, User.find(@existing_user.id).default_ssl_account
      assert_nil   ssl.approval_token
      assert_nil   ssl.token_expires
      assert       ssl.approved
      page.must_have_content 'roles: account_admin'
      page.must_have_content "account number: #{@invited_ssl_acct.acct_number}"
    end
  end
  
  describe 'Unauthorized user' do
    before do
      ssl = SslAccountUser.where(
        ssl_account_id: @invited_ssl_acct.id, user_id: @existing_user.id
      ).first
      refute_nil   ssl.approval_token
      refute_nil   ssl.token_expires
      refute       ssl.approved
      assert_equal 1, @existing_user.get_all_approved_accounts.count
      assert_equal 1, @unauthorized_user.get_all_approved_accounts.count

      click_on 'Logout'
      login_as(@unauthorized_user, update_cookie(self.controller.cookies, @unauthorized_user))
      email_approval_link = extract_url(email_body(:first))
      visit email_approval_link
    end
    
    it 'CANNOT approve invite' do
      # re-routed to Dashboard page
      assert_match account_path, current_path
      
      assert page.has_content? 'Teams(1)'
    end
    it 'invite remains unapproved' do
      ssl = @existing_user.ssl_account_users.find_by(ssl_account_id: @invited_ssl_acct.id)
      refute_nil   ssl.approval_token
      refute_nil   ssl.token_expires
      refute       ssl.approved
      assert_equal 1, @existing_user.get_all_approved_accounts.count
      assert_equal 1, @unauthorized_user.get_all_approved_accounts.count      
    end
  end
end
