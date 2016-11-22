require 'test_helper'

describe 'Disable user' do
  before do
    initialize_roles
    @account_admin     = create(:user, :account_admin)
    @account_admin_2   = create(:user, :account_admin)
    @account_admin_ssl = @account_admin.ssl_account
    @sysadmin          = create(:user, :sysadmin)
    (1..4).to_a.each {|n| create_and_approve_user(@account_admin_ssl, "ssl_user_#{n}")}
    
    @disable_user     = User.find_by(login: 'ssl_user_1')
    @disable_user_ssl = SslAccountUser.where(
      user_id: @disable_user.id, ssl_account_id: @account_admin_ssl.id
    ).first
    approve_user_for_account(@account_admin_2.ssl_account, @disable_user)
    refute @disable_user.is_disabled?(@account_admin_ssl) # NOT disabled
    assert_equal 3, @disable_user.get_all_approved_accounts.count
  end

  describe 'by sysadmin user' do
    before do
      login_as(@sysadmin, update_cookie(self.controller.cookies, @sysadmin))
      visit account_path
      click_on 'Users'
      first('td', text: @disable_user.email).click # expand user's row
      find('#user_status_disabled').set(true)      # check disable radio btn
      delete_all_cookies
      click_on 'Logout'
    end
      
    describe 'CANNOT access' do
      it 'ALL associated accounts' do
        assert_equal 0, @disable_user.get_all_approved_accounts.count
        assert       @disable_user.is_admin_disabled?
        login_as(@disable_user, update_cookie(self.controller.cookies, @disable_user))
        
        @disable_user.ssl_accounts.each do |ssl|
          visit account_path
          visit switch_default_ssl_account_user_path(
            @disable_user, ssl_account_id: ssl.id
          )
          assert_match root_path, current_path
        end
      end
    end
  end

  describe 'by account_admin' do
    before do
      # account_admin disables user
      login_as(@account_admin, self.controller.cookies)
      visit account_path
      click_on 'Users'
      first('td', text: @disable_user.email).click # expand user's row
      find('#user_status_disabled').set(true)      # check disable radio btn
      click_on 'Logout'
      login_as(@disable_user, update_cookie(self.controller.cookies, @disable_user))
      visit account_path
    end
    
    describe 'CANNOT access' do
      it 'account_admins account' do
        assert       @disable_user.is_disabled?(@account_admin_ssl) # IS disabled
        assert_equal @disable_user.get_all_approved_accounts.first.id, @disable_user.default_ssl_account
        assert_equal 2, @disable_user.get_all_approved_accounts.count
        # cannot swith to account_admins account
        visit switch_default_ssl_account_user_path(@disable_user, ssl_account_id: @account_admin_ssl.id)
        assert_match root_path, current_path
        visit account_path
        page.must_have_content "ssl account information for #{@disable_user.login}"
        page.must_have_content "account number: #{@disable_user.ssl_account.acct_number}"
        assert_equal           @disable_user.get_all_approved_accounts.first.id, @disable_user.default_ssl_account
        assert_equal           2, @disable_user.get_all_approved_accounts.count
      end
    end
    
    describe 'CAN access' do
      it 'their own account' do
        page.must_have_content "ssl account information for #{@disable_user.login}"
        page.must_have_content "account number: #{@disable_user.ssl_account.acct_number}"
        assert_equal           2, @disable_user.get_all_approved_accounts.count
      end
      it 'other associated accounts' do
        # CAN switch to another invited/enabled ssl account of @account_admin_2
        visit switch_default_ssl_account_user_path(
          @disable_user, ssl_account_id: @account_admin_2.ssl_account.id
        )
        page.must_have_content "ssl account information for #{@disable_user.login}"
        page.must_have_content "account number: #{@account_admin_2.ssl_account.acct_number}"
        assert_equal           @account_admin_2.ssl_account.id, @disable_user.default_ssl_account
      end
    end
  end

  describe 'other users on disabled users account' do
    before do
      @other_user_on_account = User.find_by(login: 'ssl_user_2')
      approve_user_for_account(@disable_user.ssl_account, @other_user_on_account)

      assert_equal 3, @other_user_on_account.get_all_approved_accounts.count
      assert_equal 3, @disable_user.get_all_approved_accounts.count

      login_as(@sysadmin, update_cookie(self.controller.cookies, @sysadmin))
      visit account_path
      click_on 'Users'
      first('td', text: @disable_user.email).click # expand user's row
      find('#user_status_disabled').set(true)      # check disable radio btn
      click_on 'Logout'
      delete_all_cookies
    end

    it 'CANNOT access the disabled users account' do
      assert_equal 2, @other_user_on_account.get_all_approved_accounts.count
      assert_equal 0, @disable_user.get_all_approved_accounts.count

      login_as(@other_user_on_account, update_cookie(self.controller.cookies, @other_user_on_account))
      visit account_path
      page.must_have_content "ssl account information for #{@other_user_on_account.login}"
      page.must_have_content "account number: #{@other_user_on_account.ssl_account.acct_number}"

      visit switch_default_ssl_account_user_path(
        @other_user_on_account, ssl_account_id: @disable_user.ssl_account.id
      )
      # cannot switch to @disable_user's ssl account
      page.must_have_content "ssl account information for #{@other_user_on_account.login}"
      page.must_have_content "account number: #{@other_user_on_account.ssl_account.acct_number}"
    end
    it 'CAN access other accounts' do
      login_as(@other_user_on_account, update_cookie(self.controller.cookies, @other_user_on_account))
      
      # can view own account
      visit account_path
      page.must_have_content "ssl account information for #{@other_user_on_account.login}"
      page.must_have_content "account number: #{@other_user_on_account.ssl_account.acct_number}"
      
      # can view/switch to @account_admin's invited ssl account
      visit switch_default_ssl_account_user_path(
        @other_user_on_account, ssl_account_id: @account_admin.ssl_account.id
      )
      visit account_path
      page.must_have_content "ssl account information for #{@other_user_on_account.login}"
      page.must_have_content "account number: #{@account_admin.ssl_account.acct_number}"
      assert_equal           @account_admin.ssl_account.id, User.find_by(login: 'ssl_user_2').default_ssl_account
    end
  end
end
