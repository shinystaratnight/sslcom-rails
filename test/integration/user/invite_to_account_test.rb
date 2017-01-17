require 'test_helper'
# 
# account_admin invites (new to SSL.com) user to their ssl account
# 
describe 'new user' do
  before do
    initialize_roles
    @new_user_email   = 'new_user@domain.com'
    @current_admin    = create(:user, :account_admin)
    @invited_ssl_acct = @current_admin.ssl_account
    
    login_as(@current_admin, self.controller.cookies)
    visit account_path
    click_on 'Users'
    click_on 'Invite User'
    fill_in  'user_email', with: @new_user_email
    find('input[value="Invite"]').click
    sleep 1 # allow time to generate notification email
    @new_user     = User.find_by(email: @new_user_email)
    @new_user_ssl = @new_user.ssl_accounts.where.not(id: @invited_ssl_acct.id).first
  end

  it 'invited user receives signup_invitation email' do
    assert_equal    1, email_total_deliveries
    assert_match    "#{@current_admin.login} has invited you to SSL.com", email_subject
    assert_match    @new_user_email, email_to
    assert_match    'noreply@ssl.com', email_from
    assert_includes email_body, @new_user.perishable_token
  end
  it 'users index: account_admin view' do
    assert_match users_path, current_path
    page.must_have_content('Username')
    page.must_have_content(@new_user_email)
    page.must_have_content('Account Type')
    page.must_have_content(Role::SSL_USER)
    page.must_have_content('Last Login')
    page.must_have_content('never')
    page.must_have_content('Status')
    page.must_have_content('not activated')
    page.must_have_content('Approved')
    page.must_have_content('approved')

    find('img[alt="Expand"]').click

    page.must_have_content('change roles')
    page.must_have_content('remove user from this account')
  end
  it 'users index: sysadmin view' do
    sysadmin = create(:user, :sysadmin)
    click_on 'Logout'
    login_as(sysadmin, update_cookie(self.controller.cookies, sysadmin))
    visit account_path
    click_on 'Users'

    # Invited user row
    page.must_have_content(@new_user_email)
    page.must_have_content('ssl_user/account_admin')
    # expand row
    first('td', text: @new_user_email).click
    page.must_have_content("remove user from account: ##{@invited_ssl_acct.acct_number.upcase}")
    page.must_have_content("remove user from account: ##{@new_user_ssl.acct_number.upcase}")
    page.must_have_content("#{@invited_ssl_acct.acct_number} [ approved ]")
    page.must_have_content("#{@new_user_ssl.acct_number} [ approved ]")
  end
  it 'user is NOT activated' do
    refute @new_user.active
  end
  it 'invited ssl account approved' do
    assert @new_user.get_all_approved_accounts.include? @invited_ssl_acct
  end
  it 'user associated with 2 ssl accounts (own and invited)' do
    assert_equal 2, @new_user.ssl_accounts.count
    assert_equal 2, @new_user.roles.count
    assert_equal 2, @new_user.get_all_approved_accounts.count
  end
  it 'user roles are set for 2 ssl accounts' do
    assert_equal @all_roles.sort, @new_user.roles.ids.sort
    # own ssl account (default: account admin)
    assert_equal @acct_admin_role, @new_user.assignments.where.not(ssl_account_id: @invited_ssl_acct.id).map(&:role_id) 
    # invited ssl account (default: ssl_user)
    assert_equal @ssl_user_role, @new_user.assignments.where(ssl_account_id: @invited_ssl_acct.id).map(&:role_id)
  end
  it 'users own ssl account approved and default' do
    ssl = @new_user.ssl_account_users.where.not(ssl_account_id: @invited_ssl_acct.id).first
    
    refute_nil   @new_user.default_ssl_account
    assert_equal @new_user.ssl_account.id, @new_user.default_ssl_account
    # account is approved, no invitation token
    assert_nil   ssl.approval_token
    assert_nil   ssl.token_expires
    assert       ssl.approved
  end
end
# 
# account_admin invites existing SSL.com user to their ssl account
# 
describe 'existing user' do
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
      user: {login: 'existing_user', password: 'Testing_ssl+1', password_confirmation: 'Testing_ssl+1'}
    )

    login_as(@current_admin, self.controller.cookies)
    visit account_path
    click_on 'Users'
    click_on 'Invite User'
    fill_in  'user_email', with: @existing_user_email
    find('input[value="Invite"]').click
    sleep 1 # allow time to generate notification email in case of delay
  end
  it 'invited user receives invite_to_account email' do
    approval_token = SslAccountUser.where(
      ssl_account_id: @invited_ssl_acct.id, user_id: @existing_user.id
    ).first.approval_token
    assert_equal    2, email_total_deliveries
    assert_match    'Invition to SSL.com', email_subject(:first)
    assert_match    @existing_user_email, email_to(:first)
    assert_match    @current_admin.email, email_from(:first)
    assert_includes email_body(:first), approval_token
  end
  it 'account_admin user receives invite_to_account_notify_admin email' do
    message = "You have added a new user #{@existing_user.email} to your SSL.com account."
    assert_equal    2, email_total_deliveries
    assert_match    'You have invited a user to your SSL.com account', email_subject
    assert_match    @current_admin.email, email_to
    assert_match    'noreply@ssl.com', email_from
    assert_includes email_body, message
  end
  it 'users index: account_admin view' do
    assert_match users_path, current_path
    page.must_have_content('Username')
    page.must_have_content('existing_user')
    page.must_have_content('Account Type')
    page.must_have_content(Role::SSL_USER) # default role
    page.must_have_content('Last Login')
    page.must_have_content('never')
    page.must_have_content('Status')
    page.must_have_content('activated') # pre-existing user
    page.must_have_content('Approved')
    page.must_have_content('sent') # approval token sent, not approved by user yet

    find('img[alt="Expand"]').click

    page.must_have_content('change roles')
    page.must_have_content('remove user from this account')
  end
  it 'users index: sysadmin view' do
    sysadmin = create(:user, :sysadmin)
    click_on 'Logout'
    login_as(sysadmin, update_cookie(self.controller.cookies, sysadmin))
    visit account_path
    click_on 'Users'

    # Invited user row
    page.must_have_content('existing_user')
    page.must_have_content(@existing_user_email)
    page.must_have_content('ssl_user/account_admin')
    #expand row
    find('td', text: @existing_user_email).click

    page.must_have_content("remove user from account: ##{@invited_ssl_acct.acct_number.upcase}")
    page.must_have_content("remove user from account: ##{@existing_user_ssl.acct_number.upcase}")
    page.must_have_content("#{@invited_ssl_acct.acct_number} [ sent ]")
    page.must_have_content("#{@existing_user_ssl.acct_number} [ approved ]")
  end
  it 'invited ssl account NOT approved' do
    refute @existing_user.get_all_approved_accounts.include? @invited_ssl_acct
  end
  it 'user associated with 2 ssl accounts (own and invited)' do
    assert_equal 2, @existing_user.ssl_accounts.count
    assert_equal 2, @existing_user.roles.count
    assert_equal 1, @existing_user.get_all_approved_accounts.count
  end
  it 'user roles are set for 2 ssl accounts' do
    assert_equal @all_roles.sort, @existing_user.roles.ids.sort
    # own ssl account (default: account admin)
    assert_equal @acct_admin_role, @existing_user.assignments.where(ssl_account_id: @existing_user_ssl.id).map(&:role_id) 
    # invited ssl account (default: ssl_user)
    assert_equal @ssl_user_role, @existing_user.assignments.where(ssl_account_id: @invited_ssl_acct.id).map(&:role_id)
  end
  it 'users own ssl account approved and default' do
    ssl = SslAccountUser.where(
      ssl_account_id: @existing_user_ssl.id, user_id: @existing_user.id
    ).first
    
    refute_nil   @existing_user.default_ssl_account
    assert_equal @existing_user_ssl.id, @existing_user.default_ssl_account
    # account is approved, no invitation token
    assert_nil   ssl.approval_token
    assert_nil   ssl.token_expires
    assert       ssl.approved
  end
  it 'invited ssl account is NOT approved' do
    ssl = SslAccountUser.where(
      ssl_account_id: @invited_ssl_acct.id, user_id: @existing_user.id
    ).first
    # account NOT approved, approval token generated for invited account
    refute_nil ssl.approval_token
    refute_nil ssl.token_expires
    refute     ssl.approved
  end
end
