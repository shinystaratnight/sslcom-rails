# frozen_string_literal: true
require 'rails_helper'

describe User do
  let!(:owner) { create(:user, :owner) }

  it_behaves_like 'it has roles'

  describe 'attributes' do
    it { is_expected.to have_db_column :login }
    it { is_expected.to have_db_column :first_name }
    it { is_expected.to have_db_column :last_name }
    it { is_expected.to have_db_column :email }
    it { is_expected.to have_db_column :active }
    it { is_expected.to have_db_column :default_ssl_account }
    it { is_expected.to have_db_column :main_ssl_account }
    it { is_expected.to have_db_column :max_teams }

    it '#max_teams_reached returns an integer' do
      user = create(:user)
      expect(User::OWNED_MAX_TEAMS).to eq user.max_teams
    end
  end

  describe 'validations' do
    let(:user) { build(:user) }

    it 'is valid' do
      expect(user).to be_valid
    end

    it 'requires email' do
      user.email = nil
      expect(user).not_to be_valid
    end

    it 'requires unique email' do
      create(:user, email: 'dupe@domain.com')
      user.email = 'dupe@domain.com'
      expect(user).not_to be_valid
    end

    it 'requires valid email' do
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

    it 'has default_ssl_account if assigned role' do
      user = create(:user, :owner)
      expect(user.default_ssl_account).not_to be_nil
    end
  end

  describe '#phone_verified?' do
    context 'returns false' do
      it 'when user does not have authy_user attribute ' do
        user = create(:user, authy_user: nil)
        expect(user.phone_verified?).to eq false
      end

      it 'when user is not registered with authy' do
        user = create(:user, authy_user: '261071388')
        VCR.use_cassette('authy_user_does_not_exist') do
          expect(user.phone_verified?).to eq false
        end
      end

      it 'when phone is different' do
        user = create(:user, authy_user: '261071388', phone: '1234512345')
        VCR.use_cassette('authy_user_exists') do
          expect(user.phone_verified?).to eq false
        end
      end
    end

    context 'returns true' do
      it 'when user has the same phone number' do
        user = create(:user, authy_user: '261071388', phone: '1234567891', phone_prefix: '1')
        VCR.use_cassette('authy_user_exists') do
          expect(user.phone_verified?).to eq true
        end
      end
    end
  end

  describe '#requires_phone_verification?' do
    it 'returns false when user is registered with authy' do
      user = create(:user, authy_user: '261071388', phone: '1234567891', phone_prefix: '1')
      VCR.use_cassette('authy_user_exists') do
        expect(user.requires_phone_verification?).to eq false
      end
    end

    context 'returns true' do
      it 'when phone_prefix changed' do
        user = create(:user, authy_user: '261071388', phone: '1234567891', phone_prefix: '1')
        VCR.use_cassette('authy_user_exists') do
          user.phone_prefix = 'Greece'
          expect(user.requires_phone_verification?).to eq true
        end
      end

      it 'when phone number changed' do
        user = create(:user, authy_user: '261071388', phone: '1234567891', phone_prefix: '1')
        user.phone = '1234512345'
        VCR.use_cassette('authy_user_exists') do
          expect(user.requires_phone_verification?).to eq true
        end
      end

      it 'when phone not registered with authy' do
        user = create(:user, authy_user: '261071388', phone: '1234567891', phone_prefix: '1')
        VCR.use_cassette('authy_user_does_not_exist') do
          expect(user.requires_phone_verification?).to eq true
        end
      end

      it 'when user.authy_user attribute is nil' do
        user = create(:user, authy_user: nil)
        VCR.use_cassette('authy_user_does_not_exist') do
          expect(user.requires_phone_verification?).to eq true
        end
      end
    end
  end

  describe 'ssl_account' do
    let!(:invited) { create(:user, :owner) }

    before do
      approve_user_for_account(owner.ssl_account, invited)
      approve_user_for_account(owner.ssl_account, invited)
    end

    xit 'get users own ssl account' do
      assert_equal invited.ssl_accounts.first, invited.ssl_account
    end

    xit 'default to main_ssl_account IF default_ssl_account=nil' do
      invited.update(default_ssl_account: nil, main_ssl_account: owner.ssl_account.id)

      assert_equal owner.ssl_account.id, invited.ssl_account.id
      assert_equal owner.ssl_account.id, invited.default_ssl_account
    end

    xit 'defaults to 1st approved account IF default_ssl_account=nil AND main_ssl_account=nil' do
      invited.update(default_ssl_account: nil, main_ssl_account: nil)

      first_approved_ssl = invited.send(:get_first_approved_acct).id
      assert_equal first_approved_ssl, invited.ssl_account.id
      assert_equal first_approved_ssl, invited.default_ssl_account
    end

    xit 'defaults to main_ssl_account IF default_ssl_account NOT approved' do
      invited.update(default_ssl_account: owner.ssl_account.id, main_ssl_account: owner.ssl_account.id)
      invited.ssl_account_users.where(ssl_account_id: owner.ssl_account.id).first.update(approved: false)

      assert_equal 3, invited.ssl_accounts.count
      assert_equal 2, invited.get_all_approved_accounts.count
      assert_equal owner.ssl_account.id, invited.ssl_account.id
      assert_equal owner.ssl_account.id, invited.default_ssl_account
    end

    xit 'defaults to 1st approved account IF default_ssl_account AND main_ssl_account ARE NOT approved' do
      invited.update(default_ssl_account: owner.ssl_account.id, main_ssl_account: owner.ssl_account.id)
      invited.ssl_account_users.where(ssl_account_id: owner.ssl_account.id).first.update(approved: false)
      invited.ssl_account_users.where(ssl_account_id: owner.ssl_account.id).first.update(approved: false)

      assert_equal 3, invited.ssl_accounts.count
      assert_equal 1, invited.get_all_approved_accounts.count
      assert_equal invited.ssl_accounts.first.id, invited.ssl_account.id
      assert_equal invited.ssl_accounts.first.id, invited.default_ssl_account
    end

    xit 'set default_ssl_account IF nil' do
      invited.update(default_ssl_account: nil)
      assert_nil invited.default_ssl_account
      refute_nil invited.ssl_account
      refute_nil invited.default_ssl_account
    end
  end

  describe 'account helper methods' do
    let!(:owner) { create(:user, :owner) }

    it '#create_ssl_account it should create/approve/add ssl_account' do
      previous_ssl_account = owner.default_ssl_account

      assert_equal SslAccountUser.where(user_id: owner.id).first.ssl_account_id, previous_ssl_account
      new_ssl_account = nil
      expect { new_ssl_account = owner.create_ssl_account }.to change { owner.ssl_accounts.count }.by(1)

      expect(owner.default_ssl_account).to eq previous_ssl_account
      owner.user_approved_invite?(ssl_account_id: new_ssl_account.id).should be_truthy
    end

    it '#create_ssl_account it should set roles if provided' do
      account = owner.create_ssl_account([Role.get_owner_id, Role.get_billing_id])
      params = { ssl_account_id: account[:id] }

      owner.assignments.where(params).count.should eq 2
      owner.assignments.where(params.merge(role_id: Role.get_owner_id)).count.should eq 1
      owner.assignments.where(params.merge(role_id: Role.get_billing_id)).count.should eq 1
    end

    it '#approve_account it should approve account and clear token info' do
      this = create(:user, :owner)
      default_ssl = this.ssl_account
      ssl_params = { ssl_account_id: default_ssl.id }
      this.set_approval_token(ssl_params)
      ssl = this.ssl_account_users.where(ssl_params).first

      expect(ssl.approval_token).not_to be_nil
      expect(ssl.token_expires).not_to be_nil
      ssl.approved.should be_falsey

      this.send(:approve_account, ssl_params)
      ssl = this.ssl_account_users.where(ssl_params).first

      expect(ssl.approval_token).to be_nil
      expect(ssl.token_expires).to be_nil
      expect(ssl.approved).to be_truthy
    end

    xit '#get_all_approved_accounts return approved accounts' do
      default_ssl = owner.ssl_account
      ssl_params = { ssl_account_id: default_ssl.id }

      expect { owner.set_approval_token(ssl_params) }.to change { owner.get_all_approved_accounts.count }.by(-1) # unapprove account
    end
  end

  describe 'role helper methods' do
    let(:owner) { create(:user, :owner) }

    xit '#set_roles_for_account it should set roles' do
      prev_roles = owner.roles.count
      new_roles  = [Role.get_reseller_id, Role.get_billing_id]
      owner.set_roles_for_account(owner.ssl_account, new_roles)

      assert_equal prev_roles + new_roles.count, owner.roles.count
    end

    it '#set_roles_for_account it should ignore unassociated ssl_account' do
      other_ssl_account = create(:user, :owner).ssl_account
      prev_roles        = owner.roles.count
      owner.set_roles_for_account(other_ssl_account, [Role.get_owner_id])

      owner.roles.count.should eq prev_roles
    end

    it '#set_roles_for_account it should ignore duplicate roles' do
      prev_roles = owner.roles.count
      owner.set_roles_for_account(owner.ssl_account, [Role.get_owner_id])

      owner.roles.count.should eq prev_roles
    end

    xit '#roles_for_account it should return array of role ids' do
      owner.set_roles_for_account(owner.ssl_account, [Role.get_reseller_id, Role.get_billing_id])

      assert owner.roles.map(&:id) == owner.roles_for_account(owner.ssl_account)
    end

    it '#roles_for_account it should ignore unassociated ssl_account' do
      other_ssl_account = create(:user, :owner).ssl_account

      assert_equal [], owner.roles_for_account(other_ssl_account)
    end

    xit '#get_roles_by_name it should return all assignments' do
      current = create(:user, :owner)
      expect(current.get_roles_by_name(Role::OWNER).count).to eq 1
    end

    xit '#update_account_role it should update assignment' do
      assert_equal 1, owner.roles.count

      owner.update_account_role(owner.ssl_account, Role::OWNER, Role::BILLING)

      assert_equal 1, owner.roles.count
      assert_equal Role.get_billing_id, owner.roles.first.id
      assert_equal 0, owner.assignments.where(role_id: Role.get_owner_id).count
    end

    xit '#assign_roles it should add new roles' do
      assert_equal 1, owner.roles.count
      owner.assign_roles(user: {
                           ssl_account_id: owner.ssl_account.id,
                           role_ids: [Role.get_reseller_id, Role.get_billing_id]
                         })

      assert_equal 3, owner.roles.count
      assert_equal [Role.get_owner_id, Role.get_reseller_id, Role.get_billing_id].sort,
                   owner.roles_for_account(owner.ssl_account).sort
    end

    xit '#assign_roles it should ignore duplicate roles' do
      assert_equal 1, owner.roles.count
      owner.assign_roles(user: {
                           ssl_account_id: owner.ssl_account.id,
                           role_ids: [Role.get_owner_id]
                         })

      assert_equal 1, owner.roles.count
      assert_equal 1, owner.assignments.count
    end

    xit '#remove_roles it should destroy all roles not passed in role_ids' do
      roles = [Role.get_reseller_id, Role.get_billing_id]
      owner.assign_roles(user: {
                           ssl_account_id: owner.ssl_account.id,
                           role_ids: roles
                         })
      assert_equal 3, owner.roles.count

      owner.remove_roles(user: {
                           ssl_account_id: owner.ssl_account.id,
                           role_ids: roles
                         })

      assert_equal 2, owner.roles.count
      assert_equal 2, owner.assignments.count
      assert_equal roles.sort, owner.assignments.map(&:role_id).sort
      assert_equal roles.sort, owner.roles.ids.sort
    end

    xit '#roles_list_for_user it should return scoped list for non admin' do
      assert_equal Role.get_select_ids_for_owner.sort, described_class.roles_list_for_user(owner).ids.sort
    end

    xit '#roles_list_for_user it should return all roles for admins' do
      sysadmin = create(:user, :sys_admin)
      expect(described_class.roles_list_for_user(sysadmin).ids.sort).to eq Role.all.ids.sort

      super_user = create(:user, :super_user)
      expect(described_class.roles_list_for_user(super_user).ids.sort).to eq Role.all.ids.sort
    end

    xit '#get_user_accounts_roles it should return a mapped hash' do
      roles = [Role.get_reseller_id, Role.get_billing_id]
      expect(described_class.get_user_accounts_roles(owner)).to eq [owner.ssl_account.id, [Role.get_owner_id]].to_h

      owner.set_roles_for_account(owner.ssl_account, roles)
      roles << Role.get_owner_id
      expect(described_class.get_user_accounts_roles(owner)).to eq [[owner.ssl_account.id, roles.sort]].to_h
    end

    xit '#get_user_accounts_roles_names it should return a mapped hash' do
      # e.g.: {'team_1': ['owner'], 'team_2': ['account_admin', 'installer']}
      assert_equal [[owner.ssl_account.get_team_name, ['owner']]].to_h, described_class.get_user_accounts_roles_names(owner)

      owner.set_roles_for_account(owner.ssl_account, [Role.get_reseller_id, Role.get_billing_id])
      assert_equal [[owner.ssl_account.get_team_name, %w[owner reseller billing]]].to_h, described_class.get_user_accounts_roles_names(owner)
    end

    xit '#role_symbols it should return [scoped role_symbols] for non-admin' do
      assert_equal [:owner], owner.role_symbols(owner.ssl_account)

      # scope to default ssl account when no account provided
      assert_equal [:owner], owner.role_symbols
    end

    xit '#role_symbols it should return [scoped role_symbols] for sysadmin' do
      owner.create_ssl_account([Role.get_role_id(Role::SYS_ADMIN)])
      # it should pull 1 role from default ssl account,
      # ignore newly created (sysadmin) role for another ssl account
      assert_equal [:owner], owner.role_symbols
    end

    xit '#role_symbols it should return [scoped role_symbols] for super_user' do
      owner.create_ssl_account([Role.get_role_id(Role::SUPER_USER)])
      # it should pull 1 role from default ssl account,
      # ignore newly created (super_user) role for another ssl account
      assert_equal [:owner], owner.role_symbols
    end

    it 'assigns sysadmin role' do
      role_sysadmin = Role.find_by(name: Role::SYS_ADMIN)
      owner.elevate_role(Role::SYS_ADMIN)
      owner.reload
      expect(owner.roles.include?(role_sysadmin)).to eq true
    end

    it 'assigns super_user role' do
      role_super_user = Role.find_by(name: Role::SUPER_USER)
      owner.elevate_role(Role::SUPER_USER)
      owner.reload
      expect(owner.roles.include?(role_super_user)).to eq true
    end
  
    it 'removes admin role' do
      role_sysadmin = Role.find_by(name: Role::SYS_ADMIN)
      owner.elevate_role(Role::SYS_ADMIN)
      owner.reload
      owner.remove_admin
      owner.reload
      expect(owner.roles.include?(role_sysadmin)).to eq false
    end
  end

  skip 'approval token helpers' do
    let!(:owner) { create(:user, :owner) }
    let!(:user_w_token) { create(:user, :owner) }
    let!(:ssl_prms_token) { { ssl_account_id: user_w_token.ssl_account.id, skip_match: true } }

    before do
      user_w_token.set_approval_token(ssl_account_id: user_w_token.ssl_account.id)
    end

    it '#approval_token_valid? false if account approved' do
      ssl_params = { ssl_account_id: owner.ssl_account.id }
      expect(owner).not_to be_approval_token_valid(ssl_params)
    end

    it '#approval_token_valid? false if token expired' do
      assert user_w_token.approval_token_valid?(ssl_prms_token)
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

      owner.set_approval_token(ssl_account_id: owner.ssl_account.id)
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

      owner.set_approval_token(ssl_account_id: owner.ssl_account.id, clear: true)
      ssl = owner.ssl_account_users.first
      # account is NOT approved and token info is nil
      assert_nil ssl.approval_token
      assert_nil ssl.token_expires
      refute     ssl.approved
    end

    it '#approval_token_not_expired true when not expired' do
      expect(user_w_token).to be_approval_token_not_expired(ssl_account_id: user_w_token.ssl_accounts.first.id)
    end

    xit '#approval_token_not_expired false when expired' do
      travel_to(Time.current + 400.days) do
        expect(user_w_token).not_to be_approval_token_not_expired(ssl_account_id: user_w_token.ssl_accounts.first.id)
      end
    end

    it '#pending_account_invites? it should return correct boolean' do
      user_w_token.pending_account_invites?.should be_truthy
      owner.pending_account_invites?.should be_falsey
    end

    xit '#get_pending_accounts it should return array of hashes' do
      ssl = user_w_token.ssl_account_users.first
      expected_hash = {
        acct_number: user_w_token.ssl_accounts.first.acct_number,
        ssl_account_id: ssl.ssl_account_id,
        approval_token: ssl.approval_token
      }
      expect(user_w_token.get_pending_accounts).to eq [expected_hash]
    end

    it '#decline_invite it should decline invite' do
      params = { ssl_account_id: user_w_token.ssl_account_users.first.ssl_account_id }
      user_w_token.user_declined_invite?(params).should be_falsey
      user_w_token.decline_invite(params)
      user_w_token.user_declined_invite?(params).should be_truthy
    end
  end

  describe 'user invite helpers' do
    describe '#invite_new_user' do
      xit 'it should create new user and ssl_account (pre-approved)' do
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
        assert_equal 1, new_user.get_all_approved_accounts.count
        assert_equal [Role.get_owner_id], new_user.roles.ids
        refute_nil   new_user.default_ssl_account

        # account is approved, no invitation token
        assert_nil   ssl.approval_token
        assert_nil   ssl.token_expires
        assert       ssl.approved
      end
    end

    describe '#invite_existing_user' do
      xit 'it should NOT create user or ssl_account, it should generate invite token' do
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
        assert_equal 1, existing_user.get_all_approved_accounts.count
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
      xit '#max_teams_reached? it should return correct boolean' do
        user_2_teams = create(:user, :owner, max_teams: 2)
        user_2_teams.create_ssl_account([Role.get_owner_id])
        expect(user_2_teams).to be_max_teams_reached
      end

      xit '#total_teams_owned it should return owned ssl accounts/teams' do
        user_2_teams = create(:user, :owner)
        expect { user_2_teams.create_ssl_account([Role.get_owner_id]) }.to change { described_class.total_teams_owned(user_2_teams.id).count }.by(1)
      end

      xit '#total_teams_can_manage_users it should return correct ssl accounts/teams' do
        user_2_teams = create(:user, :owner)

        expect { user_2_teams.create_ssl_account([Role.get_account_admin_id]) }.to change { described_class.total_teams_owned(user_2_teams.id).count }.by(1) # CAN manage users: account_admin role
      end

      it '#set_default_team it should update user' do
        user      = create(:user, :owner)
        ssl_own   = user.ssl_accounts.first
        create(:ssl_account)

        assert_nil user.main_ssl_account
        user.set_default_team(ssl_own)
        assert_equal ssl_own.id, user.main_ssl_account
      end

      it '#set_default_team it should ignore if user does not own team' do
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
        assert_equal 2, invited_user.get_all_approved_accounts.count
        assert_equal :pending, invited_user.team_status(invited_ssl_acct)

        # user DECLINES team invitation
        invited_user.decline_invite(params)
        assert_equal 2, invited_user.get_all_approved_accounts.count
        assert_equal :declined, invited_user.team_status(invited_ssl_acct)

        # user ACCEPTS team invitation
        invited_user.set_approval_token(params)
        invited_user.send(:approve_account, ssl_account_id: invited_ssl_acct.id)
        assert_equal 3, invited_user.get_all_approved_accounts.count
        assert_equal :accepted, invited_user.team_status(invited_ssl_acct)

        # invitation EXPIRED
        invited_user.set_approval_token(params)
        invited_user.ssl_account_users.where(params).first.update(token_expires: 1.day.ago)
        assert_equal 2, invited_user.get_all_approved_accounts.count
        assert_equal :expired, invited_user.team_status(invited_ssl_acct)

        # NEW user is invited
        invited_user.update(active: false)
        invited_user.set_approval_token(params)
        assert_equal 2, invited_user.get_all_approved_accounts.count
        assert_equal :pending, invited_user.team_status(invited_ssl_acct)
      end
    end
  end
end
