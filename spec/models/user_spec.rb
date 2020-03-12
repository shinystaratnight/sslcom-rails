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

require 'rails_helper'

describe User do
  before(:all) do
    initialize_roles
  end

  %i[login first_name last_name email active default_ssl_account main_ssl_account max_teams].each do |column|
    it { should have_db_column column.to_sym }
  end

  describe 'attributes' do
    it '#max_teams_reached returns an integer' do
      user = create(:user, :owner)
      user.max_teams.should eq User::OWNED_MAX_TEAMS
    end
  end

  describe 'validations' do
    let!(:user) { build(:user) }

    it 'should be valid' do
      expect(user).to be_valid
    end

    it 'should require email' do
      user.email = nil
      expect(user).not_to be_valid
    end

    it 'should require unique email' do
      existing = create(:user, :owner)
      user.email = existing.email
      expect(user).not_to be_valid
    end

    it 'should require valid email' do
      user.email = 'invalid_email.com'
      expect(user).not_to be_valid

      user.email = 'invalid_email@'
      expect(user).not_to be_valid

      user.email = '<valid@domain.com>'
      expect(user).not_to be_valid

      user.email = 'invalid_email'
      expect(user).not_to be_valid

      user.email = 'invalid_email.com'
      expect(user).not_to be_valid

      user.email = 'valid_email@domain.com'
      expect(user).to be_valid
    end

    it 'should have default_ssl_account if assigned role' do
      user = create(:user, :owner)
      expect(user.default_ssl_account).not_to be_nil
    end
  end

  describe 'roles' do
    xit 'should be able to set role sysadmin' do
      sysadmin = create(:user, :sysadmin)

      assert sysadmin.is_admin?
    end

    xit 'should be able to set role super_user' do
      super_user = create(:user, :super_user)

      assert super_user.is_super_user?
    end

    it 'should be able to set role owner' do
      owner = create(:user, :owner)

      assert owner.is_owner?
    end

    it 'should be able to set role account_admin' do
      account_admin = create(:user, :account_admin)

      assert account_admin.is_account_admin?
    end

    it 'should be able to set role reseller' do
      reseller = create(:user, :reseller)

      assert reseller.is_reseller?
    end

    it 'should be able to set role billing' do
      billing = create(:user, :billing)

      assert billing.is_billing?
    end
    it 'should be able to set role installer' do
      installer = create(:user, :installer)

      assert installer.is_installer?
    end

    it 'should be able to set role validations' do
      validations = create(:user, :validations)

      assert validations.is_validations?
    end

    it 'should be able to set role users_manager' do
      users_manager = create(:user, :users_manager)

      assert users_manager.is_users_manager?
    end
  end

  describe 'ssl_account' do
    let!(:default_ssl) { create(:user, :owner).ssl_account }
    let!(:main_ssl) { create(:user, :owner).ssl_account }
    let!(:invited_user) { create(:user, :owner) }

    before(:each) do
      approve_user_for_account(default_ssl, invited_user)
      approve_user_for_account(main_ssl, invited_user)
    end

    xit 'get users own ssl account' do
      invited_user.ssl_account.should eq invited_user.ssl_accounts.first
    end

    xit 'default to main_ssl_account IF default_ssl_account=nil' do
      invited_user.update_attributes(default_ssl_account: nil, main_ssl_account: main_ssl.id)

      invited_user.ssl_account.id.should eq main_ssl.id
      invited_user.default_ssl_account.should eq main_ssl.id
    end

    xit 'defaults to 1st approved account IF default_ssl_account=nil AND main_ssl_account=nil' do
      invited_user.update_attributes(default_ssl_account: nil, main_ssl_account: nil)

      first_approved_ssl = invited_user.send(:get_first_approved_acct).id
      invited_user.ssl_account.id.should eq first_approved_ssl
      invited_user.default_ssl_account.should eq first_approved_ssl
    end

    xit 'defaults to main_ssl_account IF default_ssl_account NOT approved' do
      invited_user.update_attributes(default_ssl_account: default_ssl.id, main_ssl_account: main_ssl.id)
      invited_user.ssl_account_users.where(ssl_account_id: default_ssl.id).first.update(approved: false)

      invited_user.ssl_accounts.count.should eq 3
      invited_user.approved_ssl_accounts.count.should eq 2
      invited_user.ssl_account.id.should eq main_ssl.id
      invited_user.default_ssl_account.should eq main_ssl.id
    end

    xit 'defaults to 1st approved account IF default_ssl_account AND main_ssl_account ARE NOT approved' do
      invited_user.update_attributes(default_ssl_account: default_ssl.id, main_ssl_account: main_ssl.id)
      invited_user.ssl_account_users.where(ssl_account_id: default_ssl.id).first.update(approved: false)
      invited_user.ssl_account_users.where(ssl_account_id: main_ssl.id).first.update(approved: false)

      invited_user.ssl_accounts.count.should eq 3
      invited_user.approved_ssl_accounts.count.should eq 1
      invited_user.ssl_account.id.should eq invited_user.ssl_account.id
      invited_user.default_ssl_account.should eq invited_user.ssl_account.id
    end
  end

  describe 'account helper methods' do
    let!(:owner) { create(:user) }

    it '#create_ssl_account should create/approve/add ssl_account' do
      owner.create_ssl_account
      owner.ssl_accounts.count.should eq 1

      previous_ssl_account = owner.default_ssl_account

      SslAccountUser.where(user_id: owner.id).first.ssl_account_id.should be previous_ssl_account

      new_ssl_account = owner.create_ssl_account

      owner.ssl_accounts.count.should eq 2
      owner.default_ssl_account.should_not be_nil
      # should not overwrite default_ssl_account id previously set
      previous_ssl_account.should eq owner.default_ssl_account
      # ssl account should be automatically approved
      owner.user_approved_invite?(ssl_account_id: new_ssl_account.id).should be_truthy
    end

    it '#approve_account should approve account and clear token info' do
      owner = create(:user, :owner)
      default_ssl = owner.ssl_account
      ssl_params = { ssl_account_id: default_ssl.id }
      owner.set_approval_token(ssl_params)
      ssl = owner.ssl_account_users.where(ssl_params).first

      ssl.approval_token
      ssl.token_expires.should_not be_nil
      ssl.approved.should be_falsey

      owner.send(:approve_account, ssl_params)
      ssl = owner.ssl_account_users.where(ssl_params).first

      ssl.approval_token.should be_nil
      ssl.token_expires.should be_nil
      ssl.approved.should be_truthy
    end

    it '#approved_ssl_accounts return approved accounts' do
      owner = create(:user, :owner)
      default_ssl = owner.ssl_account
      ssl_params = { ssl_account_id: default_ssl.id }
      assert_equal 1, owner.approved_ssl_accounts.count

      owner.set_approval_token(ssl_params) # unapprove account
      assert_equal 0, owner.approved_ssl_accounts.count
    end
  end

  describe 'role helper methods' do
    let(:owner) { create(:user, :owner) }
    let(:default_ssl) { owner.ssl_account }
    let(:reseller_role) { create(:role, :reseller).id }
    let(:billing_role) { create(:role, :billing).id }

    it '#set_roles_for_account should set roles' do
      prev_roles = owner.roles.count
      new_roles  = [reseller_role, billing_role]
      owner.set_roles_for_account(default_ssl, new_roles)

      assert_equal prev_roles + new_roles.count, owner.roles.count
    end

    it '#set_roles_for_account should ignore unassociated ssl_account' do
      other_ssl_account = create(:user, :owner).ssl_account
      prev_roles        = owner.roles.count
      owner.set_roles_for_account(other_ssl_account, [owner_role])

      owner.roles.count.should eq prev_roles
    end

    it '#set_roles_for_account should ignore duplicate roles' do
      prev_roles = owner.roles.count
      owner.set_roles_for_account(default_ssl, [owner_role])

      owner.roles.count.should eq prev_roles
    end

    it '#roles_for_account should return array of role ids' do
      owner.set_roles_for_account(default_ssl, [reseller_role, billing_role])

      assert owner.roles.map(&:id) == owner.roles_for_account(default_ssl)
    end

    it '#roles_for_account should ignore unassociated ssl_account' do
      other_ssl_account = create(:user, :owner).ssl_account

      owner.roles_for_account(other_ssl_account).should be_empty
    end

    it '#get_roles_by_name should return all assignments' do
      assert_equal 1, owner.get_roles_by_name(Role::OWNER).count
      assert_equal 0, owner.get_roles_by_name(Role::BILLING).count
    end

    xit '#update_account_role should update assignment' do
      assert_equal 1, owner.roles.count

      owner.update_account_role(default_ssl, Role::OWNER, Role::BILLING)

      assert_equal 1, owner.roles.count
      assert_equal billing_role, owner.roles.first.id
      assert_equal 0, owner.assignments.where(role_id: owner_role).count
    end

    xit '#assign_roles should add new roles' do
      owner.roles.count.should eq 1
      owner.assign_roles(user: {
                           ssl_account_id: default_ssl.id,
                           role_ids: [reseller_role, billing_role]
                         })

      owner.roles.count.should eq 3
      [owner_role, reseller_role, billing_role].sort.should eq [owner.roles_for_account(default_ssl).sort]
    end

    it '#assign_roles should ignore duplicate roles' do
      owner.roles.count.should eq 1
      owner.assign_roles(user: { ssl_account_id: default_ssl.id, role_ids: [owner_role] })
      owner.roles.count.should eq 1
      owner.assignments.count.should eq 1
    end

    it '#remove_roles should destroy all roles not passed in role_ids' do
      roles = [reseller_role, billing_role]
      owner.assign_roles(user: {
                           ssl_account_id: default_ssl.id,
                           role_ids: roles
                         })
      assert_equal 3, owner.roles.count

      owner.remove_roles(user: {
                           ssl_account_id: default_ssl.id,
                           role_ids: roles
                         })

      assert_equal 2, owner.roles.count
      assert_equal 2, owner.assignments.count
      assert_equal roles.sort, owner.assignments.map(&:role_id).sort
      assert_equal roles.sort, owner.roles.ids.sort
    end

    it '#roles_list_for_user should return scoped list for non admin' do
      User.roles_list_for_user(owner).ids.sort.should eq Role.for_owners.pluck(:id)
    end

    xit '#roles_list_for_user should return all roles for admins' do
      sysadmin = create(:user, :sysadmin)
      User.roles_list_for_user(sysadmin).ids.sort.should eq Role.all.ids.sort

      super_user = create(:user, :super_user)
      User.roles_list_for_user(super_user).ids.sort.should eq Role.all.ids.sort
    end

    xit '#get_user_accounts_roles should return a mapped hash' do
      # e.g.: { ssl_1_id: [role_ids], ssl_2_id: [role_ids] }
      roles = [reseller_role, billing_role]
      [default_ssl.id, [owner_role]].to_h.should eq User.get_user_accounts_roles(owner)

      owner.set_roles_for_account(default_ssl, roles)
      roles << owner_role
      [default_ssl.id, roles.sort].to_h.should eq User.get_user_accounts_roles(owner)
    end

    xit '#get_user_accounts_roles_names should return a mapped hash' do
      # e.g.: {'team_1': ['owner'], 'team_2': ['account_admin', 'installer']}
      assert_equal [[default_ssl.get_team_name, ['owner']]].to_h, User.get_user_accounts_roles_names(owner)

      owner.set_roles_for_account(default_ssl, [reseller_role, billing_role])
      assert_equal [[default_ssl.get_team_name, %w[owner reseller billing]]].to_h, User.get_user_accounts_roles_names(owner)
    end

    it '#role_symbols should return [scoped role_symbols] for non-admin' do
      assert_equal [:owner], owner.role_symbols(default_ssl)

      # scope to default ssl account when no account provided
      assert_equal [:owner], owner.role_symbols
    end

    it '#role_symbols should return [scoped role_symbols] for sysadmin' do
      owner.create_ssl_account([Role.get_role_id(Role::SYSADMIN)])
      # should pull 1 role from default ssl account,
      # ignore newly created (sysadmin) role for another ssl account
      assert_equal [:owner], owner.role_symbols
    end

    it '#role_symbols should return [scoped role_symbols] for super_user' do
      owner.create_ssl_account([Role.get_role_id(Role::SUPER_USER)])
      # should pull 1 role from default ssl account,
      # ignore newly created (super_user) role for another ssl account
      assert_equal [:owner], owner.role_symbols
    end
  end

  describe 'approval token helpers' do
    let!(:owner) { create(:user, :owner) }
    let!(:default_ssl) { owner.ssl_account }
    let!(:user_w_token) { create(:user, :owner) }
    let!(:ssl_prms_token) { { ssl_account_id: user_w_token.ssl_account.id, skip_match: true } }
    before(:each) do
      user_w_token.set_approval_token(ssl_account_id: user_w_token.ssl_account.id)
    end

    it '#approval_token_valid? false if account approved' do
      ssl_params = { ssl_account_id: default_ssl.id }

      owner.approval_token_valid?(ssl_params).should be_falsey
    end

    it '#approval_token_valid? false if token expired' do
      user_w_token.approval_token_valid?(ssl_prms_token).should be_truthy
      user_w_token.ssl_account_users.first.update(
        token_expires: (DateTime.now - 2.hours) # expire token
      )
      user_w_token.approval_token_valid?(ssl_prms_token).should be_falsey
    end

    it '#approval_token_valid? false if token does not match' do
      valid_token = user_w_token.ssl_account_users.first.approval_token
      ssl_prms_token[:skip_match] = false

      user_w_token.approval_token_valid?(ssl_prms_token.merge(token: valid_token)).should be_truthy
      user_w_token.approval_token_valid?(ssl_prms_token.merge(token: 'does not match')).should be_falsey
    end

    it '#set_approval_token sets a valid token' do
      # There is no ssl_account_users which leads to no id
      ssl = owner.ssl_account_users.first
      assert_nil ssl.approval_token
      assert_nil ssl.token_expires
      assert     ssl.approved

      owner.set_approval_token(ssl_account_id: default_ssl.id)
      ssl = owner.ssl_account_users.first
      refute_nil ssl.approval_token
      refute_nil ssl.token_expires
      refute     ssl.approved
    end

    it '#set_approval_token w/clear param deletes token' do
      ssl = owner.ssl_account_users.first
      assert_nil ssl.approval_token
      assert_nil ssl.token_expires
      assert     ssl.approved

      owner.set_approval_token(ssl_account_id: default_ssl.id, clear: true)
      ssl = owner.ssl_account_users.first
      # account is NOT approved and token info is nil
      assert_nil ssl.approval_token
      assert_nil ssl.token_expires
      refute     ssl.approved
    end

    it '#approval_token_not_expired true when not expired' do
      user_w_token.approval_token_not_expired?(ssl_account_id: user_w_token.ssl_accounts.first.id).should be_truthy
    end

    it '#approval_token_not_expired false when expired' do
      user_w_token.ssl_account_users.first.update(token_expires: (DateTime.now - 2.hours))
      user_w_token.approval_token_not_expired?(ssl_account_id: user_w_token.ssl_accounts.first.id).should be_falsey
    end

    it '#pending_account_invites? should return correct boolean' do
      user_w_token.pending_account_invites?.should be_truthy
      owner.pending_account_invites?.should be_falsey
    end

    it '#get_pending_accounts should return array of hashes' do
      ssl = user_w_token.ssl_account_users.first
      expected_hash = {
        acct_number: user_w_token.ssl_accounts.first.acct_number,
        ssl_account_id: ssl.ssl_account_id,
        approval_token: ssl.approval_token
      }
      assert_equal [expected_hash], user_w_token.get_pending_accounts
    end

    it '#decline_invite should decline invite' do
      params = { ssl_account_id: user_w_token.ssl_account_users.first.ssl_account_id }
      user_w_token.user_declined_invite?(params).should be_falsey
      user_w_token.decline_invite(params)
      user_w_token.user_declined_invite?(params).should be_truthy
    end
  end

  describe 'user invite helpers' do
    describe '#invite_new_user' do
      it 'should create new user and ssl_account (pre-approved)' do
        invite_user = create(:user, :owner)
        new_user = invite_user.invite_new_user(
          user: { email: 'new_user@domain.com' },
          root_url: 'root_url',
          from_user: invite_user
        )
        ssl = new_user.ssl_account_users.first

        assert       new_user.persisted?
        refute       new_user.active
        assert       new_user.ssl_account
        assert_equal 1, new_user.ssl_accounts.count
        assert_equal 1, new_user.roles.count
        assert_equal 1, new_user.approved_ssl_accounts.count
        assert_equal [Role.get_owner_id], new_user.roles.ids
        refute_nil   new_user.default_ssl_account

        # account is approved, no invitation token
        assert_nil   ssl.approval_token
        assert_nil   ssl.token_expires
        assert       ssl.approved
      end
    end

    describe '#invite_existing_user' do
      it 'should NOT create user or ssl_account, should generate invite token' do
        invite_user   = create(:user, :owner)
        existing_user = create(:user, :owner, email: 'existing_user@domain.com')
        params        = {
          user: { email: existing_user.email },
          # Problem is that ssl account is not created.
          ssl_account_id: invite_user.ssl_account.id,
          root_url: 'root_url.com',
          from_user: invite_user
        }

        # existing user only has one ssl_account with role 'owner'
        assert_equal 1, existing_user.ssl_accounts.count
        assert_equal 1, existing_user.roles.count
        assert_equal 1, existing_user.approved_ssl_accounts.count
        assert_equal [Role.get_owner_id], existing_user.roles.ids

        existing_user.ssl_accounts << invite_user.ssl_account
        existing_user.set_roles_for_account(invite_user.ssl_account, @acct_admin_role)
        existing_user.invite_existing_user(params)
        ssl = existing_user.ssl_account_users.where(
          ssl_account_id: invite_user.ssl_account.id
        ).first

        # existing user now has two accounts and added role 'account_admin' for invited account
        assert_equal 2, existing_user.ssl_accounts.count
        assert_equal 2, existing_user.roles.count
        assert_equal Role.get_role_ids([Role::OWNER, Role::ACCOUNT_ADMIN]).sort, existing_user.roles.ids.sort
        # account NOT approved, approval token generated for invited account
        refute_nil ssl.approval_token
        refute_nil ssl.token_expires
        refute     ssl.approved
      end
    end

    describe 'team helpers' do
      xit '#max_teams_reached? should return correct boolean' do
        user_2_teams = create(:user, :owner, max_teams: 2)
        assert_equal 2, user_2_teams.max_teams
        assert_equal 1, user_2_teams.ssl_accounts.distinct.count
        assert_equal 1, user_2_teams.assignments.count
        refute user_2_teams.max_teams_reached?

        # User owns a second ssl account/team, max has been reached
        # This is not working either because of the ssl_account
        user_2_teams.create_ssl_account([Role.get_owner_id])

        assert_equal 2, user_2_teams.ssl_accounts.count
        assert_equal 2, user_2_teams.assignments.count
        assert user_2_teams.max_teams_reached?
      end

      xit '#total_teams_owned should return owned ssl accounts/teams' do
        user_2_teams = create(:user, :owner)
        assert_equal 1, user_2_teams.ssl_accounts.count
        assert_equal 1, user_2_teams.assignments.count
        assert_equal 1, user_2_teams.total_teams_owned.count

        # User owns a second ssl account/team
        user_2_teams.create_ssl_account([Role.get_owner_id])

        assert_equal 2, user_2_teams.ssl_accounts.count
        assert_equal 2, user_2_teams.assignments.count
        assert_equal 2, user_2_teams.total_teams_owned.count
      end

      xit '#total_teams_can_manage_users should return correct ssl accounts/teams' do
        user_2_teams = create(:user, :owner) # CAN manage users: owner role
        assert_equal 1, user_2_teams.ssl_accounts.count
        assert_equal 1, user_2_teams.assignments.count
        assert_equal 1, user_2_teams.total_teams_can_manage_users.count

        user_2_teams.create_ssl_account(@acct_admin_role) # CAN manage users: account_admin role
        assert_equal 2, user_2_teams.ssl_accounts.count
        assert_equal 2, user_2_teams.assignments.count
        assert_equal 2, user_2_teams.total_teams_can_manage_users.count

        user_2_teams.create_ssl_account([@billing_role]) # CANNOT manage users: billing role
        assert_equal 3, user_2_teams.ssl_accounts.count
        assert_equal 3, user_2_teams.assignments.count
        assert_equal 2, user_2_teams.total_teams_can_manage_users.count
      end

      it '#set_default_team should update user' do
        user = create(:user, :owner)
        ssl_own = user.ssl_accounts.first
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
        invited_ssl_acct = create(:ssl_account)
        params           = { ssl_account_id: invited_ssl_acct.id }
        invited_user.ssl_accounts << invited_ssl_acct

        # user is invited
        invited_user.set_approval_token(params)
        invited_user.approved_ssl_accounts.count.should eq 1
        invited_user.team_status(invited_ssl_acct).should be :pending

        # user DECLINES team invitation
        invited_user.decline_invite(params)
        invited_user.approved_ssl_accounts.count.should eq 1
        invited_user.team_status(invited_ssl_acct).should be :declined

        # user ACCEPTS team invitation
        invited_user.set_approval_token(params)
        invited_user.send(:approve_account, ssl_account_id: invited_ssl_acct.id)
        invited_user.approved_ssl_accounts.count.should eq 2
        invited_user.team_status(invited_ssl_acct).should be :accepted

        # invitation EXPIRED
        invited_user.set_approval_token(params)
        invited_user.ssl_account_users.where(params).first.update_attribute(:token_expires, 1.day.ago)
        invited_user.approved_ssl_accounts.count.should eq 1
        invited_user.team_status(invited_ssl_acct).should be :expired

        # NEW user is invited
        invited_user.update_attribute(:active, false)
        invited_user.set_approval_token(params)
        invited_user.approved_ssl_accounts.count.should eq 1
        invited_user.team_status(invited_ssl_acct).should be :pending
      end
    end
  end
end
