require 'test_helper'
# 
# Only existing SSL.com user can receive account invite with approval token.
# 
describe 'user approves ssl account invite' do
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
    find('input[alt="Register"]').click
  end

  describe 'BEFORE Approved: invited user' do
    it 'can only see their own account' do
      ssl = @existing_user.ssl_account_users.find_by(ssl_account_id: @invited_ssl_acct.id)

      click_on 'Logout'
      login_as(@existing_user, update_cookie(self.controller.cookies, @existing_user))
      visit account_path

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
  end

  describe 'AFTER Approved: invited user' do
    before do
      click_on 'Logout'
      login_as(@existing_user, update_cookie(self.controller.cookies, @existing_user))
      email_approval_link = URI.extract(email_body(:first)).first.gsub('http://www.ssl.com', '')
      visit email_approval_link
    end
    
    it 'can see both accounts' do
      page.must_have_content 'ACCOUNT'
      page.must_have_content 'Users'
      page.must_have_content @existing_user_ssl.acct_number.upcase
      assert_equal 2, @existing_user.get_all_approved_accounts.count
    end
    it 'can switch to invited ssl account' do
      ssl = @existing_user.ssl_account_users.find_by(ssl_account_id: @invited_ssl_acct.id)
      find('div.acc-sel-dropbtn').click # ACCOUNT dropdown
      find('a', text: @invited_ssl_acct.acct_number.upcase).click
      
      assert page.has_no_content? 'Users'
      assert_equal @invited_ssl_acct.id, User.find(@existing_user.id).default_ssl_account
      assert_nil   ssl.approval_token
      assert_nil   ssl.token_expires
      assert       ssl.approved
    end
  end
end
