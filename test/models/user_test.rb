require 'test_helper'

class UserTest < Minitest::Spec

  before do
    create_reminder_triggers
    create_roles
    @account_admin_role = Role.get_role_id(Role::ACCOUNT_ADMIN)
    @vetter_role        = Role.get_role_id(Role::VETTER)
    @reseller_role      = Role.get_role_id(Role::RESELLER)
    @ssl_user_role      = Role.get_role_id(Role::SSL_USER)
  end

  describe 'attributes' do
    before(:each)  { @user = create(:user) }

    it { assert_respond_to @user, :login }
    it { assert_respond_to @user, :first_name }
    it { assert_respond_to @user, :last_name }
    it { assert_respond_to @user, :email }
    it { assert_respond_to @user, :active }
    it { assert_respond_to @user, :default_ssl_account }

    it '#first_name returns a string' do
      assert_match 'first name', @user.first_name
    end
    it '#last_name returns a string' do
      assert_match 'last name', @user.last_name
    end
    it '#login returns a string' do
      assert_includes @user.login, 'user_login'
    end
    it '#email returns a string' do
      assert_includes @user.email, '@domain.com'
    end
  end

  describe 'validations' do
    it 'should be valid' do
      assert build(:user).valid?
    end
    it 'should require email' do
      refute build(:user, email: nil).valid?
    end
    it 'should require unique email' do
      create(:user, email: 'dupe@domain.com')
      refute build(:user, email: 'dupe@domain.com').valid?
    end
    it 'should have default_ssl_account if assigned role' do
      user = create(:user, :account_admin)
      refute_nil user.default_ssl_account
    end
  end

  describe 'roles' do
    it 'should be able to set role sysadmin' do
      assert create(:user, :sysadmin).is_admin?
    end
    it 'should be able to set role super_user' do
      assert create(:user, :super_user).is_super_user?
    end
    it 'should be able to set role account_admin' do
      assert create(:user, :account_admin).is_account_admin?
    end
    it 'should be able to set role ssl_user' do
      assert create(:user, :ssl_user).is_ssl_user?
    end
    it 'should be able to set role reseller' do
      assert create(:user, :reseller).is_reseller?
    end
    it 'should be able to set role vetter' do
      assert create(:user, :vetter).is_vetter?
    end
  end

  describe 'account helper methods' do
    before(:all) do
      @account_admin = create(:user, :account_admin)
      @default_ssl   = @account_admin.ssl_account
    end
    
    it '#ssl_account should get default ssl_account' do
      refute_nil @account_admin.ssl_account
    end
    it '#ssl_account should set default_ssl_account if nil' do
      @account_admin.update(default_ssl_account: nil)
      assert_nil @account_admin.default_ssl_account
      refute_nil @account_admin.ssl_account
      refute_nil @account_admin.default_ssl_account
    end

    it '#create_ssl_account should create/approve/add ssl_account' do
      previous_ssl_account = @account_admin.default_ssl_account
      assert_equal 1, @account_admin.ssl_accounts.count
      assert_equal SslAccountUser.where(user_id: @account_admin.id).first.ssl_account_id, previous_ssl_account
      
      new_ssl_account = @account_admin.create_ssl_account

      assert_equal 2, @account_admin.ssl_accounts.count
      refute_nil @account_admin.default_ssl_account
      # should not overwrite default_ssl_account id previously set
      assert_equal previous_ssl_account, @account_admin.default_ssl_account
      # ssl account should be automatically approved
      assert @account_admin.user_approved_invite?(ssl_account_id: new_ssl_account.id)
    end

    it '#create_ssl_account should set roles if provided' do
      params = { ssl_account_id: 
        @account_admin.create_ssl_account([@account_admin_role, @vetter_role])
      }
      assert_equal 2, @account_admin.assignments.where(params).count
      assert_equal 1, @account_admin.assignments.where(params.merge(role_id: @account_admin_role)).count
      assert_equal 1, @account_admin.assignments.where(params.merge(role_id: @vetter_role)).count
    end

    it '#approve_account should approve account and clear token info' do
      ssl_params = {ssl_account_id: @default_ssl.id}
      @account_admin.set_approval_token(ssl_params)
      ssl = @account_admin.ssl_account_users.where(ssl_params).first
      
      refute_nil ssl.approval_token
      refute_nil ssl.token_expires
      refute     ssl.approved

      @account_admin.send(:approve_account, ssl_params)
      ssl = @account_admin.ssl_account_users.where(ssl_params).first

      assert_nil ssl.approval_token
      assert_nil ssl.token_expires
      assert     ssl.approved
    end

    it '#get_all_approved_accounts return approved accounts' do
      ssl_params = {ssl_account_id: @default_ssl.id}
      assert_equal 1, @account_admin.get_all_approved_accounts.count

      @account_admin.set_approval_token(ssl_params) # unapprove account
      assert_equal 0, @account_admin.get_all_approved_accounts.count
    end

  end

  describe 'role helper methods' do
    before(:all) { 
      @account_admin = create(:user, :account_admin)
      @default_ssl   = @account_admin.ssl_account 
    }

    it '#set_roles_for_account should set roles' do
      prev_roles = @account_admin.roles.count
      new_roles  = [@reseller_role, @vetter_role]
      @account_admin.set_roles_for_account(@default_ssl, new_roles)
      
      assert_equal prev_roles+new_roles.count, @account_admin.roles.count
    end
    
    it '#set_roles_for_account should ignore unassociated ssl_account' do
      other_ssl_account = create(:user, :account_admin).ssl_account
      prev_roles        = @account_admin.roles.count
      @account_admin.set_roles_for_account(other_ssl_account, [@account_admin_role])
      
      assert_equal prev_roles, @account_admin.roles.count
    end
    
    it '#set_roles_for_account should ignore duplicate roles' do
      prev_roles = @account_admin.roles.count
      @account_admin.set_roles_for_account(@default_ssl, [@account_admin_role])
      
      assert_equal prev_roles, @account_admin.roles.count
    end

    it '#roles_for_account should return array of role ids' do
      @account_admin.set_roles_for_account(@default_ssl, [@reseller_role, @vetter_role])
      
      assert_equal [@account_admin_role, @reseller_role, @vetter_role].sort, 
        @account_admin.roles_for_account(@default_ssl).sort
    end

    it '#roles_for_account should ignore unassociated ssl_account' do
      other_ssl_account = create(:user, :account_admin).ssl_account
      
      assert_equal [], @account_admin.roles_for_account(other_ssl_account)
    end

    it '#get_roles_by_name should return all assignments' do
      assert_equal 1, @account_admin.get_roles_by_name(Role::ACCOUNT_ADMIN).count
      assert_equal 0, @account_admin.get_roles_by_name(Role::VETTER).count
    end
    
    it '#update_account_role should update assignment' do
      assert_equal 1, @account_admin.roles.count
      assert_equal @account_admin_role, @account_admin.roles.first.id

      @account_admin.update_account_role(@default_ssl, Role::ACCOUNT_ADMIN, Role::VETTER)

      assert_equal 1, @account_admin.roles.count
      assert_equal @vetter_role, @account_admin.roles.first.id
      assert_equal 0, @account_admin.assignments.where(role_id: @account_admin_role).count
    end

    it '#assign_roles should add new roles' do
      assert_equal 1, @account_admin.roles.count
      @account_admin.assign_roles( user: {
        ssl_account_id: @default_ssl.id,
        role_ids:       [@reseller_role, @vetter_role] }
      )

      assert_equal 3, @account_admin.roles.count
      assert_equal [@account_admin_role, @reseller_role, @vetter_role].sort, 
        @account_admin.roles_for_account(@default_ssl).sort      
    end
    
    it '#assign_roles should ignore duplicate roles' do
      assert_equal 1, @account_admin.roles.count
      @account_admin.assign_roles( user: {
        ssl_account_id: @default_ssl.id,
        role_ids:       [@account_admin_role] }
      )

      assert_equal 1, @account_admin.roles.count
      assert_equal 1, @account_admin.assignments.count
    end

    it '#remove_roles should destroy all roles not passed in role_ids' do
      roles = [@reseller_role, @vetter_role]
      @account_admin.assign_roles( user: {
        ssl_account_id: @default_ssl.id,
        role_ids:       roles }
      )
      assert_equal 3, @account_admin.roles.count

      @account_admin.remove_roles( user: {
        ssl_account_id: @default_ssl.id,
        role_ids:       roles }
      )

      assert_equal 2, @account_admin.roles.count
      assert_equal 2, @account_admin.assignments.count
      assert_equal roles.sort, @account_admin.assignments.map(&:role_id).sort
      assert_equal roles.sort, @account_admin.roles.ids.sort
    end

    it '#roles_list_for_user should return scoped list for non admin' do
      # only show ssl_user in dropdown select list 
      assert_equal Role.get_role_ids(Role::SSL_USER), User.roles_list_for_user(@account_admin).ids.sort
    end

    it '#roles_list_for_user should return all roles for admins' do
      sysadmin = create(:user, :sysadmin)
      assert_equal Role.all.ids.sort, User.roles_list_for_user(sysadmin).ids.sort

      super_user = create(:user, :super_user)
      assert_equal Role.all.ids.sort, User.roles_list_for_user(super_user).ids.sort
    end

    it '#get_user_accounts_roles should return a mapped hash' do
      # e.g.: { ssl_1_id: [role_ids], ssl_2_id: [role_ids] }
      roles = [@reseller_role, @vetter_role]
      assert_equal [[@default_ssl.id, [@account_admin_role]]].to_h, User.get_user_accounts_roles(@account_admin)
      
      @account_admin.set_roles_for_account(@default_ssl, roles)
      roles << @account_admin_role
      assert_equal [[@default_ssl.id, roles.sort]].to_h, User.get_user_accounts_roles(@account_admin)
    end

    it '#role_symbols should return [role_sumbols] for non-admin' do
      assert_equal [:account_admin], @account_admin.role_symbols(@default_ssl)
      
      # scope to default ssl account when no account provided
      assert_equal [:account_admin], @account_admin.role_symbols
    end

    it '#role_symbols should return all [role_sumbols] for sysadmin' do
      @account_admin.create_ssl_account([Role.get_role_id(Role::SYS_ADMIN)])
      
      # should pull all roles from all (2) accounts if sysadmin
      assert_equal [:account_admin, :sysadmin], @account_admin.role_symbols
    end

    it '#role_symbols should return all [role_sumbols] for super_user' do
      @account_admin.create_ssl_account([Role.get_role_id(Role::SUPER_USER)])

      # should pull all roles from all (2) accounts if sysadmin
      assert_equal [:account_admin, :super_user], @account_admin.role_symbols
    end
  end

  describe 'approval token helpers' do
    before(:all) { 
      @account_admin  = create(:user, :account_admin)
      @default_ssl    = @account_admin.ssl_account
      @user_w_token   = create(:user, :account_admin)
      @ssl_prms_token = { ssl_account_id: @user_w_token.ssl_account.id, skip_match: true}
      @user_w_token.set_approval_token(ssl_account_id: @user_w_token.ssl_account.id)
    }

    it '#approval_token_valid? false if account approved' do
      ssl_params = {ssl_account_id: @default_ssl.id}
      
      refute @account_admin.approval_token_valid?(ssl_params)
    end

    it '#approval_token_valid? false if token expired' do      
      assert @user_w_token.approval_token_valid?(@ssl_prms_token)
      @user_w_token.ssl_account_users.first.update( 
        token_expires: (DateTime.now - 2.hours) # expire token
      )

      refute @user_w_token.approval_token_valid?(@ssl_prms_token)
    end

    it '#approval_token_valid? false if token does not match' do
      valid_token = @user_w_token.ssl_account_users.first.approval_token
      @ssl_prms_token.merge!(skip_match: false)
      
      assert @user_w_token.approval_token_valid?(@ssl_prms_token.merge(token: valid_token))
      refute @user_w_token.approval_token_valid?(@ssl_prms_token.merge(token: 'does not match'))
    end

    it '#set_approval_token sets a valid token' do
      ssl = @account_admin.ssl_account_users.first
      assert_nil ssl.approval_token
      assert_nil ssl.token_expires
      assert     ssl.approved

      @account_admin.set_approval_token(ssl_account_id: @default_ssl.id)
      ssl = @account_admin.ssl_account_users.first
      refute_nil ssl.approval_token
      refute_nil ssl.token_expires
      refute     ssl.approved
    end

    it '#set_approval_token w/clear param deletes token' do
      ssl = @account_admin.ssl_account_users.first
      assert_nil ssl.approval_token
      assert_nil ssl.token_expires
      assert     ssl.approved

      @account_admin.set_approval_token(ssl_account_id: @default_ssl.id, clear: true)
      ssl = @account_admin.ssl_account_users.first
      # account is NOT approved and token info is nil
      assert_nil ssl.approval_token
      assert_nil ssl.token_expires
      refute     ssl.approved
    end

    it '#approval_token_not_expired true when not expired' do
      assert @user_w_token.approval_token_not_expired?(ssl_account_id: @user_w_token.ssl_account.id)
    end

    it '#approval_token_not_expired false when expired' do
      @user_w_token.ssl_account_users.first.update(token_expires: (DateTime.now - 2.hours))
      refute @user_w_token.approval_token_not_expired?(ssl_account_id: @user_w_token.ssl_account.id)
    end
  end

  describe 'user invite helpers' do
    describe '#invite_new_user' do
      it 'should create new user and ssl_account (pre-approved)' do
        invite_user  = create(:user, :account_admin)
        new_user = invite_user.invite_new_user(
          user:      {email: 'new_user@domain.com'},
          root_url:  'root_url',
          from_user: invite_user
        )
        ssl = new_user.ssl_account_users.first

        assert       new_user.persisted?
        refute       new_user.active
        assert       new_user.ssl_account
        assert_equal 1, new_user.ssl_accounts.count
        assert_equal 1, new_user.roles.count
        assert_equal 1, new_user.get_all_approved_accounts.count
        assert_equal [Role.get_role_id(Role::ACCOUNT_ADMIN)], new_user.roles.ids
        refute_nil   new_user.default_ssl_account
        
        # account is approved, no invitation token
        assert_nil   ssl.approval_token
        assert_nil   ssl.token_expires
        assert       ssl.approved
      end
    end

    describe '#invite_existing_user' do
      it 'should NOT create user or ssl_account, should generate invite token' do
        invite_user   = create(:user, :account_admin)
        existing_user = create(:user, :account_admin, email: 'existing_user@domain.com')
        params        = {
          user:           {email: existing_user.email},
          ssl_account_id: invite_user.ssl_account.id,
          root_url:       'root_url.com',
          from_user:      invite_user
        }

        # existing user only has one ssl_account with role 'account_admin'
        assert_equal 1, existing_user.ssl_accounts.count
        assert_equal 1, existing_user.roles.count
        assert_equal 1, existing_user.get_all_approved_accounts.count
        assert_equal [Role.get_role_id(Role::ACCOUNT_ADMIN)], existing_user.roles.ids

        existing_user.ssl_accounts << invite_user.ssl_account
        existing_user.set_roles_for_account(invite_user.ssl_account, [@ssl_user_role])
        existing_user.invite_existing_user(params)
        ssl = existing_user.ssl_account_users.where(
          ssl_account_id: invite_user.ssl_account.id
        ).first

        # existing user now has two accounts and added role 'ssl_user' for invited account
        assert_equal 2, existing_user.ssl_accounts.count
        assert_equal 2, existing_user.roles.count
        assert_equal Role.get_role_ids([Role::ACCOUNT_ADMIN, Role::SSL_USER]).sort, existing_user.roles.ids.sort
        # account NOT approved, approval token generated for invited account
        refute_nil ssl.approval_token
        refute_nil ssl.token_expires
        refute     ssl.approved
      end
    end
  end
end
