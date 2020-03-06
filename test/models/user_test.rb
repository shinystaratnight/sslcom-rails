# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                  :integer          not null, primary key
#  active              :boolean          default("0"), not null
#  address1            :string(255)
#  address2            :string(255)
#  address3            :string(255)
#  avatar_content_type :string(255)
#  avatar_file_name    :string(255)
#  avatar_file_size    :integer
#  avatar_updated_at   :datetime
#  city                :string(255)
#  country             :string(255)
#  crypted_password    :string(255)
#  current_login_at    :datetime
#  current_login_ip    :string(255)
#  default_ssl_account :integer
#  duo_enabled         :string(255)      default("enabled")
#  email               :string(255)      not null
#  failed_login_count  :integer          default("0"), not null
#  first_name          :string(255)
#  is_auth_token       :boolean
#  last_login_at       :datetime
#  last_login_ip       :string(255)
#  last_name           :string(255)
#  last_request_at     :datetime
#  login               :string(255)      not null
#  login_count         :integer          default("0"), not null
#  main_ssl_account    :integer
#  max_teams           :integer
#  openid_identifier   :string(255)
#  organization        :string(255)
#  password_salt       :string(255)
#  perishable_token    :string(255)      not null
#  persist_notice      :boolean          default("0")
#  persistence_token   :string(255)      not null
#  phone               :string(255)
#  po_box              :string(255)
#  postal_code         :string(255)
#  single_access_token :string(255)      not null
#  state               :string(255)
#  status              :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#  ssl_account_id      :integer
#
# Indexes
#
#  index_users_l_e                                    (login,email)
#  index_users_on_default_ssl_account                 (default_ssl_account)
#  index_users_on_email                               (email)
#  index_users_on_login                               (login)
#  index_users_on_login_and_email                     (login,email)
#  index_users_on_perishable_token                    (perishable_token)
#  index_users_on_ssl_account_id_and_login_and_email  (ssl_account_id,login,email)
#  index_users_on_ssl_acount_id                       (ssl_account_id)
#  index_users_on_status                              (id,status)
#  index_users_on_status_and_login_and_email          (status,login,email)
#  index_users_on_status_and_ssl_account_id           (id,ssl_account_id,status)
#

require 'test_helper'

describe User do
  subject { User.new }

  describe 'attributes' do
    should have_db_column :login
    should have_db_column :first_name
    should have_db_column :last_name
    should have_db_column :email
    should have_db_column :active
    should have_db_column :default_ssl_account
    should have_db_column :main_ssl_account
    should have_db_column :max_teams

    it '#max_teams_reached returns an integer' do
      user = create(:user)
      assert_equal User::OWNED_MAX_TEAMS, user.max_teams
    end
  end

  describe 'validations' do
    before :all do
      stub_roles
      stub_triggers
      stub_server_software
      SslAccount.any_instance.stubs(:create_api_credential).returns
    end

    it 'should be valid' do
      assert build(:user).valid?
    end

    it 'should require email' do
      assert_not build(:user, email: nil).valid?
    end

    it 'should require unique email' do
      create(:user, email: 'dupe@domain.com')
      assert_not build(:user, email: 'dupe@domain.com').valid?
    end

    it 'should require valid email' do
      assert_not build(:user, email: 'invalid_email.com').valid?
      assert_not build(:user, email: 'invalid_email@').valid?
      assert_not build(:user, email: '<valid@domain.com>').valid?
      assert_not build(:user, email: 'invalid_email').valid?
      assert build(:user, email: 'valid_email@domain.com').valid?
    end

    it 'should have default_ssl_account if assigned role' do
      user = create(:user, :owner)
      assert_not_nil user.default_ssl_account
    end
  end

  # describe 'roles' do
  #   it 'should be able to set role sysadmin' do
  #     sysadmin = create(:user, :sysadmin)
  #
  #     assert sysadmin.is_admin?
  #   end
  #
  #   it 'should be able to set role super_user' do
  #     super_user = create(:user, :super_user)
  #
  #     assert super_user.is_super_user?
  #   end
  #
  #   it 'should be able to set role owner' do
  #     owner = create(:user, :owner)
  #
  #     assert owner.is_owner?
  #   end
  #
  #   it 'should be able to set role account_admin' do
  #     account_admin = create(:user, :account_admin)
  #
  #     assert account_admin.is_account_admin?
  #   end
  #
  #   it 'should be able to set role reseller' do
  #     reseller = create(:user, :reseller)
  #
  #     assert reseller.is_reseller?
  #   end
  #
  #   it 'should be able to set role billing' do
  #     billing = create(:user, :billing)
  #
  #     assert billing.is_billing?
  #   end
  #   it 'should be able to set role installer' do
  #     installer = create(:user, :installer)
  #
  #     assert installer.is_installer?
  #   end
  #
  #   it 'should be able to set role validations' do
  #     validations = create(:user, :validations)
  #
  #     assert validations.is_validations?
  #   end
  #
  #   it 'should be able to set role users_manager' do
  #     users_manager = create(:user, :users_manager)
  #
  #     assert users_manager.is_users_manager?
  #   end
  # end

  # describe 'ssl_account' do
  #   before(:all) do
  #     @default_ssl      = create(:user, :owner).ssl_account
  #     @main_ssl         = create(:user, :owner).ssl_account
  #     @invited_user     = create(:user, :owner)
  #     @invited_user_id  = @invited_user.id
  #     @invited_user_ssl = @invited_user.ssl_accounts.first
  #     assert_equal 1, @invited_user.ssl_accounts.count
  #
  #     approve_user_for_account(@default_ssl, @invited_user)
  #     approve_user_for_account(@main_ssl, @invited_user)
  #     assert_equal 3, @invited_user.ssl_accounts.count
  #     assert_equal 3, @invited_user.get_all_approved_accounts.count
  #   end
  #
  #   it 'get users own ssl account' do
  #     assert_equal @invited_user_ssl, @invited_user.ssl_account
  #   end
  #
  #   it 'default to main_ssl_account IF default_ssl_account=nil' do
  #     @invited_user.update_attributes(default_ssl_account: nil, main_ssl_account: @main_ssl.id)
  #
  #     assert_equal @main_ssl.id, @invited_user.ssl_account.id
  #     assert_equal @main_ssl.id, @invited_user.default_ssl_account
  #   end
  #
  #   it 'defaults to 1st approved account IF default_ssl_account=nil AND main_ssl_account=nil' do
  #     @invited_user.update_attributes(default_ssl_account: nil, main_ssl_account: nil)
  #
  #     first_approved_ssl = @invited_user.send(:get_first_approved_acct).id
  #     assert_equal first_approved_ssl, @invited_user.ssl_account.id
  #     assert_equal first_approved_ssl, @invited_user.default_ssl_account
  #   end
  #
  #   it 'defaults to main_ssl_account IF default_ssl_account NOT approved' do
  #     @invited_user.update_attributes(default_ssl_account: @default_ssl.id, main_ssl_account: @main_ssl.id)
  #     @invited_user.ssl_account_users.where(ssl_account_id: @default_ssl.id).first.update(approved: false)
  #
  #     assert_equal 3, @invited_user.ssl_accounts.count
  #     assert_equal 2, @invited_user.get_all_approved_accounts.count
  #     assert_equal @main_ssl.id, @invited_user.ssl_account.id
  #     assert_equal @main_ssl.id, @invited_user.default_ssl_account
  #   end
  #
  #   it 'defaults to 1st approved account IF default_ssl_account AND main_ssl_account ARE NOT approved' do
  #     @invited_user.update_attributes(default_ssl_account: @default_ssl.id, main_ssl_account: @main_ssl.id)
  #     @invited_user.ssl_account_users.where(ssl_account_id: @default_ssl.id).first.update(approved: false)
  #     @invited_user.ssl_account_users.where(ssl_account_id: @main_ssl.id).first.update(approved: false)
  #
  #     assert_equal 3, @invited_user.ssl_accounts.count
  #     assert_equal 1, @invited_user.get_all_approved_accounts.count
  #     assert_equal @invited_user_ssl.id, @invited_user.ssl_account.id
  #     assert_equal @invited_user_ssl.id, @invited_user.default_ssl_account
  #   end
  #
  #   it 'set default_ssl_account IF nil' do
  #     @invited_user.update(default_ssl_account: nil)
  #     assert_nil @invited_user.default_ssl_account
  #     refute_nil @invited_user.ssl_account
  #     refute_nil @invited_user.default_ssl_account
  #   end
  # end

  describe 'account helper methods' do
    before :all do
      stub_roles
      stub_triggers
      stub_server_software
      SslAccount.any_instance.stubs(:create_api_credential).returns
      @owner = create(:user)
    end

    it '#create_ssl_account should create/approve/add ssl_account' do
      @owner.create_ssl_account
      assert_equal 1, @owner.ssl_accounts.count

      previous_ssl_account = @owner.default_ssl_account

      assert_equal SslAccountUser.where(user_id: @owner.id).first.ssl_account_id, previous_ssl_account

      new_ssl_account = @owner.create_ssl_account

      assert_equal 2, @owner.ssl_accounts.count
      assert_not_nil @owner.default_ssl_account
      # should not overwrite default_ssl_account id previously set
      assert_equal previous_ssl_account, @owner.default_ssl_account
      # ssl account should be automatically approved
      assert @owner.user_approved_invite?(ssl_account_id: new_ssl_account.id)
    end

    it '#create_ssl_account should set roles if provided' do
      owner = create(:role, :owner)
      billing = create(:role, :billing)

      params = { ssl_account_id:
        @owner.create_ssl_account([owner.id, billing.id]) }

      assert_equal 2, @owner.assignments.where(params).count
      assert_equal 1, @owner.assignments.where(params.merge(role_id: owner.id)).count
      assert_equal 1, @owner.assignments.where(params.merge(role_id: billing.id)).count
    end

    it '#approve_account should approve account and clear token info' do
      owner = create(:user, :owner)
      default_ssl = owner.ssl_account
      ssl_params = { ssl_account_id: default_ssl.id }
      owner.set_approval_token(ssl_params)
      ssl = owner.ssl_account_users.where(ssl_params).first

      assert_not_nil ssl.approval_token
      assert_not_nil ssl.token_expires
      assert_not     ssl.approved

      owner.send(:approve_account, ssl_params)
      ssl = owner.ssl_account_users.where(ssl_params).first

      assert_nil ssl.approval_token
      assert_nil ssl.token_expires
      assert     ssl.approved
    end

    # it '#get_all_approved_accounts return approved accounts' do
    #   owner = create(:user, :owner)
    #   default_ssl = owner.ssl_account
    #   ssl_params = {ssl_account_id: default_ssl.id}
    #   assert_equal 1, owner.get_all_approved_accounts.count
    #
    #   owner.set_approval_token(ssl_params) # unapprove account
    #   assert_equal 0, owner.get_all_approved_accounts.count
    # end
  end

  describe 'role helper methods' do
    before(:all) do
      stub_roles
      stub_triggers
      stub_server_software
      SslAccount.any_instance.stubs(:create_api_credential).returns
      @owner = create(:user, :owner)
      @default_ssl = @owner.ssl_account
      @reseller_role = create(:role, :reseller).id
      @billing_role = create(:role, :billing).id
    end

    # it '#set_roles_for_account should set roles' do
    #   prev_roles = @owner.roles.count
    #   new_roles  = [@reseller_role, @billing_role]
    #   @owner.set_roles_for_account(@default_ssl, new_roles)
    #
    #   assert_equal prev_roles+new_roles.count, @owner.roles.count
    # end

    it '#set_roles_for_account should ignore unassociated ssl_account' do
      other_ssl_account = create(:user, :owner).ssl_account
      prev_roles        = @owner.roles.count
      @owner.set_roles_for_account(other_ssl_account, [@owner_role])

      assert_equal prev_roles, @owner.roles.count
    end

    it '#set_roles_for_account should ignore duplicate roles' do
      prev_roles = @owner.roles.count
      @owner.set_roles_for_account(@default_ssl, [@owner_role])

      assert_equal prev_roles, @owner.roles.count
    end

    # it '#roles_for_account should return array of role ids' do
    #   @owner.set_roles_for_account(@default_ssl, [@reseller_role, @billing_role])
    #
    #   assert @owner.roles.map(&:id) == @owner.roles_for_account(@default_ssl)
    # end

    it '#roles_for_account should ignore unassociated ssl_account' do
      other_ssl_account = create(:user, :owner).ssl_account

      assert_equal [], @owner.roles_for_account(other_ssl_account)
    end

    # it '#get_roles_by_name should return all assignments' do
    #   assert_equal 1, @owner.get_roles_by_name(Role::OWNER).count
    #   assert_equal 0, @owner.get_roles_by_name(Role::BILLING).count
    # end

    # it '#update_account_role should update assignment' do
    #   assert_equal 1, @owner.roles.count
    #
    #   @owner.update_account_role(@default_ssl, Role::OWNER, Role::BILLING)
    #
    #   assert_equal 1, @owner.roles.count
    #   assert_equal @billing_role, @owner.roles.first.id
    #   assert_equal 0, @owner.assignments.where(role_id: @owner_role).count
    # end

    # it '#assign_roles should add new roles' do
    #   assert_equal 1, @owner.roles.count
    #   @owner.assign_roles( user: {
    #     ssl_account_id: @default_ssl.id,
    #     role_ids:       [@reseller_role, @billing_role] }
    #   )
    #
    #   assert_equal 3, @owner.roles.count
    #   assert_equal [@owner_role, @reseller_role, @billing_role].sort,
    #     @owner.roles_for_account(@default_ssl).sort
    # end

    # it '#assign_roles should ignore duplicate roles' do
    #   assert_equal 1, @owner.roles.count
    #   @owner.assign_roles( user: {
    #     ssl_account_id: @default_ssl.id,
    #     role_ids:       [@owner_role] }
    #   )
    #
    #   assert_equal 1, @owner.roles.count
    #   assert_equal 1, @owner.assignments.count
    # end

    # it '#remove_roles should destroy all roles not passed in role_ids' do
    #   roles = [@reseller_role, @billing_role]
    #   @owner.assign_roles( user: {
    #     ssl_account_id: @default_ssl.id,
    #     role_ids:       roles }
    #   )
    #   assert_equal 3, @owner.roles.count
    #
    #   @owner.remove_roles( user: {
    #     ssl_account_id: @default_ssl.id,
    #     role_ids:       roles }
    #   )
    #
    #   assert_equal 2, @owner.roles.count
    #   assert_equal 2, @owner.assignments.count
    #   assert_equal roles.sort, @owner.assignments.map(&:role_id).sort
    #   assert_equal roles.sort, @owner.roles.ids.sort
    # end

    # it '#roles_list_for_user should return scoped list for non admin' do
    #   # 'owner' user can only see roles: account_admin, billing, installer, validations
    #   assert_equal Role.get_select_ids_for_owner.sort, User.roles_list_for_user(@owner).ids.sort
    # end

    it '#roles_list_for_user should return all roles for admins' do
      sysadmin = create(:user, :sysadmin)
      assert_equal Role.all.ids.sort, User.roles_list_for_user(sysadmin).ids.sort

      super_user = create(:user, :super_user)
      assert_equal Role.all.ids.sort, User.roles_list_for_user(super_user).ids.sort
    end

    # it '#get_user_accounts_roles should return a mapped hash' do
    #   # e.g.: { ssl_1_id: [role_ids], ssl_2_id: [role_ids] }
    #   roles = [@reseller_role, @billing_role]
    #   assert_equal [[@default_ssl.id, [@owner_role]]].to_h, User.get_user_accounts_roles(@owner)
    #
    #   @owner.set_roles_for_account(@default_ssl, roles)
    #   roles << @owner_role
    #   assert_equal [[@default_ssl.id, roles.sort]].to_h, User.get_user_accounts_roles(@owner)
    # end

    # it '#get_user_accounts_roles_names should return a mapped hash' do
    #   # e.g.: {'team_1': ['owner'], 'team_2': ['account_admin', 'installer']}
    #   assert_equal [[@default_ssl.get_team_name, ['owner']]].to_h, User.get_user_accounts_roles_names(@owner)
    #
    #   @owner.set_roles_for_account(@default_ssl, [@reseller_role, @billing_role])
    #   assert_equal [[@default_ssl.get_team_name, ['owner', 'reseller', 'billing']]].to_h, User.get_user_accounts_roles_names(@owner)
    # end

    # it '#role_symbols should return [scoped role_symbols] for non-admin' do
    #   assert_equal [:owner], @owner.role_symbols(@default_ssl)
    #
    #   # scope to default ssl account when no account provided
    #   assert_equal [:owner], @owner.role_symbols
    # end

    # it '#role_symbols should return [scoped role_symbols] for sysadmin' do
    #   @owner.create_ssl_account([Role.get_role_id(Role::SYS_ADMIN)])
    #   # should pull 1 role from default ssl account,
    #   # ignore newly created (sysadmin) role for another ssl account
    #   assert_equal [:owner], @owner.role_symbols
    # end
    #
    # it '#role_symbols should return [scoped role_symbols] for super_user' do
    #   @owner.create_ssl_account([Role.get_role_id(Role::SUPER_USER)])
    #   # should pull 1 role from default ssl account,
    #   # ignore newly created (super_user) role for another ssl account
    #   assert_equal [:owner], @owner.role_symbols
    # end
  end

  describe 'approval token helpers' do
    before(:all) do
      stub_roles
      stub_triggers
      stub_server_software
      SslAccount.any_instance.stubs(:create_api_credential).returns
      @owner = create(:user, :owner)
      @default_ssl = @owner.ssl_account
      @user_w_token = create(:user, :owner)
      @ssl_prms_token = { ssl_account_id: @user_w_token.ssl_account.id, skip_match: true }
      @user_w_token.set_approval_token(ssl_account_id: @user_w_token.ssl_account.id)
    end

    # it '#approval_token_valid? false if account approved' do
    #   ssl_params = {ssl_account_id: @default_ssl.id}
    #
    #   refute @owner.approval_token_valid?(ssl_params)
    # end

    it '#approval_token_valid? false if token expired' do
      assert @user_w_token.approval_token_valid?(@ssl_prms_token)
      @user_w_token.ssl_account_users.first.update(
        token_expires: (DateTime.now - 2.hours) # expire token
      )

      assert_not @user_w_token.approval_token_valid?(@ssl_prms_token)
    end

    it '#approval_token_valid? false if token does not match' do
      valid_token = @user_w_token.ssl_account_users.first.approval_token
      @ssl_prms_token[:skip_match] = false

      assert @user_w_token.approval_token_valid?(@ssl_prms_token.merge(token: valid_token))
      assert_not @user_w_token.approval_token_valid?(@ssl_prms_token.merge(token: 'does not match'))
    end
    #
    # it '#set_approval_token sets a valid token' do
    #   #There is no ssl_account_users which leads to no id
    #   ssl = @owner.ssl_account_users.first
    #   assert_nil ssl.approval_token
    #   assert_nil ssl.token_expires
    #   assert     ssl.approved
    #
    #   @owner.set_approval_token(ssl_account_id: @default_ssl.id)
    #   ssl = @owner.ssl_account_users.first
    #   refute_nil ssl.approval_token
    #   refute_nil ssl.token_expires
    #   refute     ssl.approved
    # end

    # it '#set_approval_token w/clear param deletes token' do
    #   ssl = @owner.ssl_account_users.first
    #   assert_nil ssl.approval_token
    #   assert_nil ssl.token_expires
    #   assert     ssl.approved
    #
    #   @owner.set_approval_token(ssl_account_id: @default_ssl.id, clear: true)
    #   ssl = @owner.ssl_account_users.first
    #   # account is NOT approved and token info is nil
    #   assert_nil ssl.approval_token
    #   assert_nil ssl.token_expires
    #   refute     ssl.approved
    # end

    it '#approval_token_not_expired true when not expired' do
      assert @user_w_token.approval_token_not_expired?(ssl_account_id: @user_w_token.ssl_accounts.first.id)
    end

    it '#approval_token_not_expired false when expired' do
      @user_w_token.ssl_account_users.first.update(token_expires: (DateTime.now - 2.hours))
      assert_not @user_w_token.approval_token_not_expired?(ssl_account_id: @user_w_token.ssl_accounts.first.id)
    end

    it '#pending_account_invites? should return correct boolean' do
      assert @user_w_token.pending_account_invites?
      assert_not @owner.pending_account_invites?
    end

    # it '#get_pending_accounts should return array of hashes' do
    #   ssl = @user_w_token.ssl_account_users.first
    #   expected_hash = {
    #     acct_number:    @user_w_token.ssl_accounts.first.acct_number,
    #     ssl_account_id: ssl.ssl_account_id,
    #     approval_token: ssl.approval_token
    #   }
    #   assert_equal [expected_hash], @user_w_token.get_pending_accounts
    # end

    it '#decline_invite should decline invite' do
      params = { ssl_account_id: @user_w_token.ssl_account_users.first.ssl_account_id }
      assert_not @user_w_token.user_declined_invite?(params)
      @user_w_token.decline_invite(params)
      assert @user_w_token.user_declined_invite?(params)
    end
  end

  describe 'user invite helpers' do
    describe '#invite_new_user' do
      # it 'should create new user and ssl_account (pre-approved)' do
      #   invite_user  = create(:user, :owner)
      #   new_user = invite_user.invite_new_user(
      #     user:      {email: 'new_user@domain.com'},
      #     root_url:  'root_url',
      #     from_user: invite_user
      #   )
      #   ssl = new_user.ssl_account_users.first
      #
      #   assert       new_user.persisted?
      #   refute       new_user.active
      #   assert       new_user.ssl_account
      #   assert_equal 1, new_user.ssl_accounts.count
      #   assert_equal 1, new_user.roles.count
      #   assert_equal 1, new_user.get_all_approved_accounts.count
      #   assert_equal [Role.get_owner_id], new_user.roles.ids
      #   refute_nil   new_user.default_ssl_account
      #
      #   # account is approved, no invitation token
      #   assert_nil   ssl.approval_token
      #   assert_nil   ssl.token_expires
      #   assert       ssl.approved
      # end
    end

    # describe '#invite_existing_user' do
    #   it 'should NOT create user or ssl_account, should generate invite token' do
    #     invite_user   = create(:user, :owner)
    #     existing_user = create(:user, :owner, email: 'existing_user@domain.com')
    #     params        = {
    #       user:           {email: existing_user.email},
    #       # Problem is that ssl account is not created.
    #       ssl_account_id: invite_user.ssl_account.id,
    #       root_url:       'root_url.com',
    #       from_user:      invite_user
    #     }
    #
    #     # existing user only has one ssl_account with role 'owner'
    #     assert_equal 1, existing_user.ssl_accounts.count
    #     assert_equal 1, existing_user.roles.count
    #     assert_equal 1, existing_user.get_all_approved_accounts.count
    #     assert_equal [Role.get_owner_id], existing_user.roles.ids
    #
    #     existing_user.ssl_accounts << invite_user.ssl_account
    #     existing_user.set_roles_for_account(invite_user.ssl_account, @acct_admin_role)
    #     existing_user.invite_existing_user(params)
    #     ssl = existing_user.ssl_account_users.where(
    #       ssl_account_id: invite_user.ssl_account.id
    #     ).first
    #
    #     # existing user now has two accounts and added role 'account_admin' for invited account
    #     assert_equal 2, existing_user.ssl_accounts.count
    #     assert_equal 2, existing_user.roles.count
    #     assert_equal Role.get_role_ids([Role::OWNER, Role::ACCOUNT_ADMIN]).sort, existing_user.roles.ids.sort
    #     # account NOT approved, approval token generated for invited account
    #     refute_nil ssl.approval_token
    #     refute_nil ssl.token_expires
    #     refute     ssl.approved
    #   end
    # end

    describe 'team helpers' do
      before :all do
        stub_roles
        stub_triggers
        stub_server_software
        SslAccount.any_instance.stubs(:create_api_credential).returns
      end
      # it '#max_teams_reached? should return correct boolean' do
      #   user_2_teams = create(:user, :owner, max_teams: 2)
      #   assert_equal 2, user_2_teams.max_teams
      #   assert_equal 1, SslAccount.count
      #   assert_equal 1, user_2_teams.ssl_accounts.count
      #   assert_equal 1, user_2_teams.assignments.count
      #   refute user_2_teams.max_teams_reached?
      #
      #   # User owns a second ssl account/team, max has been reached
      #   #This is not working either because of the ssl_account
      #   user_2_teams.create_ssl_account([Role.get_owner_id])
      #
      #   assert_equal 2, SslAccount.count
      #   assert_equal 2, user_2_teams.ssl_accounts.count
      #   assert_equal 2, user_2_teams.assignments.count
      #   assert user_2_teams.max_teams_reached?
      # end
      # it '#total_teams_owned should return owned ssl accounts/teams' do
      #   user_2_teams = create(:user, :owner)
      #   assert_equal 1, SslAccount.count
      #   assert_equal 1, user_2_teams.ssl_accounts.count
      #   assert_equal 1, user_2_teams.assignments.count
      #   assert_equal 1, user_2_teams.total_teams_owned.count
      #
      #   # User owns a second ssl account/team
      #   user_2_teams.create_ssl_account([Role.get_owner_id])
      #
      #   assert_equal 2, SslAccount.count
      #   assert_equal 2, user_2_teams.ssl_accounts.count
      #   assert_equal 2, user_2_teams.assignments.count
      #   assert_equal 2, user_2_teams.total_teams_owned.count
      # end
      # it '#total_teams_can_manage_users should return correct ssl accounts/teams' do
      #   user_2_teams = create(:user, :owner)                # CAN manage users: owner role
      #   assert_equal 1, SslAccount.count
      #   assert_equal 1, user_2_teams.ssl_accounts.count
      #   assert_equal 1, user_2_teams.assignments.count
      #   assert_equal 1, user_2_teams.total_teams_can_manage_users.count
      #
      #   user_2_teams.create_ssl_account(@acct_admin_role) # CAN manage users: account_admin role
      #   assert_equal 2, SslAccount.count
      #   assert_equal 2, user_2_teams.ssl_accounts.count
      #   assert_equal 2, user_2_teams.assignments.count
      #   assert_equal 2, user_2_teams.total_teams_can_manage_users.count
      #
      #   user_2_teams.create_ssl_account([@billing_role])    # CANNOT manage users: billing role
      #   assert_equal 3, SslAccount.count
      #   assert_equal 3, user_2_teams.ssl_accounts.count
      #   assert_equal 3, user_2_teams.assignments.count
      #   assert_equal 2, user_2_teams.total_teams_can_manage_users.count
      # end
      it '#set_default_team should update user' do
        user      = create(:user, :owner)
        ssl_own   = user.ssl_accounts.first
        create(:ssl_account)

        assert_nil user.main_ssl_account
        user.set_default_team(ssl_own)
        assert_equal ssl_own.id, user.main_ssl_account
      end
      it '#set_default_team should ignore if user does not own team' do
        user      = create(:user, :owner)
        ssl_own   = user.ssl_accounts.first
        ssl_other = create(:ssl_account)
        assert_nil user.main_ssl_account

        user.set_default_team(ssl_own)
        assert_equal ssl_own.id, user.main_ssl_account

        user.set_default_team(ssl_other) # user does not own ssl_other
        assert_equal ssl_own.id, user.main_ssl_account
      end
      it '#team_status returns correct status' do
        invited_user = create(:user, :owner)
        invited_user.ssl_account
        invited_ssl_acct = create(:ssl_account)
        params           = { ssl_account_id: invited_ssl_acct.id }
        invited_user.ssl_accounts << invited_ssl_acct
        # invited_user.set_roles_for_account(invited_ssl_acct, @acct_admin_role)

        # user is invited
        invited_user.set_approval_token(params)
        assert_equal 1, invited_user.get_all_approved_accounts.count
        assert_equal :pending, invited_user.team_status(invited_ssl_acct)

        # user DECLINES team invitation
        invited_user.decline_invite(params)
        assert_equal 1, invited_user.get_all_approved_accounts.count
        assert_equal :declined, invited_user.team_status(invited_ssl_acct)

        # user ACCEPTS team invitation
        invited_user.set_approval_token(params)
        invited_user.send(:approve_account, ssl_account_id: invited_ssl_acct.id)
        assert_equal 2, invited_user.get_all_approved_accounts.count
        assert_equal :accepted, invited_user.team_status(invited_ssl_acct)

        # invitation EXPIRED
        invited_user.set_approval_token(params)
        invited_user.ssl_account_users.where(params).first.update_attribute(:token_expires, 1.day.ago)
        assert_equal 1, invited_user.get_all_approved_accounts.count
        assert_equal :expired, invited_user.team_status(invited_ssl_acct)

        # NEW user is invited
        invited_user.update_attribute(:active, false)
        invited_user.set_approval_token(params)
        assert_equal 1, invited_user.get_all_approved_accounts.count
        assert_equal :pending, invited_user.team_status(invited_ssl_acct)
      end
    end
  end
end
