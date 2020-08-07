class User < ApplicationRecord
  extend Memoist
  include Pagable
  include UserMessageable
  include Concerns::User::Association
  include Concerns::User::Preferences
  include Concerns::User::Validation
  include Concerns::User::Avatar
  include Concerns::User::Scope
  include Concerns::User::Notification
  include Concerns::User::Approval
  include Concerns::User::Invitation
  include Concerns::User::Team

  OWNED_MAX_TEAMS = 3

  attr_accessor :changing_password, :admin_update, :role_ids, :role_change_type, :as_reseller
  attr_accessible :login, :email, :password, :password_confirmation, :openid_identifier, :status, :assignments_attributes, :first_name, :last_name,
                  :default_ssl_account, :ssl_account_id, :role_ids, :role_change_type, :main_ssl_account, :max_teams, :persist_notice

  accepts_nested_attributes_for :assignments

  before_save :should_reset_perishable_token

  before_create do |u|
    u.status = 'enabled'
    u.max_teams = OWNED_MAX_TEAMS unless u.max_teams
  end

  delegate :tier_suffix, to: :ssl_account, prefix: false, allow_nil: true

  acts_as_authentic do |c|
    c.logged_in_timeout = 30.minutes
    c.validate_email_field = false
    c.validate_login_field = false
    c.session_ids = [nil, :shadow]
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
    c.validates_length_of_password_field_options = { on: :update, minimum: 8, if: -> { (has_no_credentials? && !admin_update) || changing_password } }
    c.validates_length_of_password_confirmation_field_options = { on: :update, minimum: 8, if: -> { (has_no_credentials? && !admin_update) || changing_password } }
  end

  def ssl_account(default_team = nil)
    SslAccount.find_by(id: Rails.cache.fetch("#{cache_key}/ssl_account/#{default_team.is_a?(Symbol) ? default_team.to_s : default_team.try(:cache_key)}") do
      default_ssl = default_ssl_account && is_approved_account?(default_ssl_account)
      main_ssl = main_ssl_account && is_approved_account?(main_ssl_account)

      # Retrieve team that was manually set as default in Teams by user
      break main_ssl_account if default_team && main_ssl

      if default_ssl
        default_ssl_account
      elsif !default_ssl && main_ssl
        set_default_ssl_account main_ssl_account
        main_ssl_account
      else
        approved_account = get_first_approved_acct
        set_default_ssl_account(approved_account) if approved_account
        approved_account
      end
    end)
  end
  memoize :ssl_account

  def is_approved_account?(target_ssl)
    Rails.cache.fetch("#{cache_key}/is_approved_account/#{target_ssl.try(:cache_key)}") do
      return false unless SslAccount.exists?(target_ssl)

      ssl_account_users.where(ssl_account_id: target_ssl, user_enabled: true, approved: true).any?
    end
  end
  memoize 'is_approved_account?'.to_sym

  def is_main_account?(ssl_account)
    return false if main_ssl_account.nil?

    ssl_account.id == main_ssl_account
  end

  def is_account_owner?(ssl_account)
    total_teams_owned.include?(ssl_account)
  end

  def is_account_team_admin?(ssl_account)
    total_teams_admin.include?(ssl_account)
  end

  def is_team_owner_admin?(ssl_account)
    assignments.where(role_id: [Role.get_owner_id, Role.get_account_admin_id], ssl_account_id: ssl_account.id).size.positive?
  end

  def role_symbols_archived_team(ssl_account)
    assignments.includes(:role).where(ssl_account_id: ssl_account.id).map { |assign| assign.role.name.to_sym }.uniq.compact
  end

  def is_first_approved_acct?(ssl_account)
    ssl_account == get_first_approved_acct
  end

  def owned_ssl_account
    total_teams_owned.first
  end

  def team_status(team)
    ssl = ssl_account_users.where(ssl_account_id: team.id).uniq.compact.first
    if ssl
      status = :accepted if active && ssl.approved
      status = :declined if ssl.declined_at || (!ssl.approved && ssl.token_expires.nil? && ssl.approval_token.nil?)
      status = :expired if ssl.token_expires && (status != :declined) && (ssl.token_expires < DateTime.now)
      status = :pending if !active && (status != :declined)
      status = :pending if active && (!ssl.approved && ssl.token_expires && ssl.approval_token) && (ssl.token_expires > DateTime.now)
    end
    status
  end

  def is_duo_required?
    is_super_user?
  end

  def is_passed_2fa(session_duo)
    status = if is_duo_required?
               session_duo
             else
               if ssl_account&.sec_type == 'duo'
                 if Settings.duo_auto_enabled || Settings.duo_custom_enabled
                   session_duo
                 else
                   true
                 end
               else
                 true
               end
             end
    status
  end

  def get_auto_add_users_teams
    ssl_accounts.joins(:assignments).where(
      assignments: { role_id: Role.can_auto_add_users }
    ).uniq.compact
  end

  def get_auto_add_users
    User.joins(:ssl_accounts).where(ssl_accounts: { id: get_auto_add_users_teams.map(&:id) }).where.not(users: { id: id }).uniq.compact
  end

  def get_auto_add_user_roles(added_user)
    role_ids = added_user.assignments.where(
      ssl_account_id: get_auto_add_users_teams.map(&:id)
    ).pluck(:role_id).uniq

    # If invited user has owner role or reseller role, then replace
    # it with account admin role for the team they're invited to.
    if role_ids.include?(Role.get_owner_id) || role_ids.include?(Role.get_reseller_id)

      # User cannot be account_admin and have other roles.
      role_ids = [Role.get_account_admin_id]
    end
    role_ids.uniq
  end

  def self.find_non_owners
    [].tap do |orphans|
      find_each do |u|
        orphans << u if u.owned_ssl_account.blank?
      end
    end
  end

  def create_ssl_account(role_ids = nil, attr = {})
    save if new_record?
    account = ssl_accounts.create(attr)
    set_roles_for_account(account, role_ids) if role_ids&.length&.positive?
    set_default_ssl_account(account) unless default_ssl_account
    approve_account(ssl_account_id: account.id)
    account
  end

  def set_default_ssl_account(account)
    account = account.is_a?(SslAccount) ? account.id : account
    update_attribute(:default_ssl_account, account)
  end

  def clear_default_ssl_account
    update_attribute(:default_ssl_account, nil)
  end

  def set_roles_for_account(account, role_ids)
    if account && ssl_accounts.include?(account) && role_ids.count.positive?
      role_ids.each do |role|
        Assignment.find_or_create_by(
          user_id: id,
          role_id: role,
          ssl_account_id: account.id
        )
      end
    end
  end

  def roles_for_account(target_ssl = ssl_account)
    if ssl_accounts.include?(target_ssl)
      assignments.where(ssl_account_id: target_ssl.id).pluck(:role_id).uniq
    else
      Assignment.none
    end
  end
  memoize :roles_for_account

  def get_roles_by_name(role_name)
    role_id = Role.get_role_id(role_name)
    role_id ? assignments.where(role_id: role_id) : []
  end

  def update_account_role(account_id, old_role, new_role)
    old_role = assignments.find_by(
      ssl_account_id: account_id, role_id: Role.get_role_id(old_role)
    )
    old_role&.update(role_id: Role.get_role_id(new_role)) unless duplicate_role?(new_role, account_id)
  end

  def duplicate_role?(role, target_ssl_id = nil)
    target_ssl = SslAccount.find_by(id: target_ssl_id)
    assignments.exists?(
      ssl_account_id: (target_ssl.nil? ? ssl_account : target_ssl).id,
      role_id: (role.is_a?(String) ? Role.get_role_id(role) : Role.find(role))
    )
  end

  def invite_user_to_account!(params)
    user_exists = User.get_user_by_email(params[:user][:email])
    user_exists || invite_new_user(params)
  end

  def invite_new_user(params)
    if params[:deliver_invite]
      User.get_user_by_email(params[:user][:email]).deliver_signup_invitation!(params[:from_user], params[:root_url], params[:invited_teams])
    else
      user = User.new(params[:user].merge(login: params[:user][:email]))
      user.signup!(params)
      ssl = user.create_ssl_account([Role.get_owner_id])
      user.update_attribute(:main_ssl_account, ssl.id) if ssl
      user.update_attribute(:persist_notice, true)

      # Check Code Signing Certificate Order for assign as assignee.
      if Settings.require_signup_password
        CertificateOrder.unscoped.search_validated_not_assigned(user.email).each do |cert_order|
          cert_order.update_attribute(:assignee, user)
          LockedRecipient.create_for_co(cert_order)
        end
      end

      user
    end
  end

  def invite_existing_user(params)
    email = params[:user][:email] if params[:user]
    ssl_acct_id = (params[:user] && params[:user][:ssl_account_id]) || params[:ssl_account_id]
    user = email ? User.get_user_by_email(email) : self
    new_params = params.merge(ssl_account_id: ssl_acct_id, skip_match: true, from_user: params[:from_user])

    if user.ssl_accounts.map(&:id).include? ssl_acct_id.to_i
      user.set_approval_token(new_params)
      if user.approval_token_valid?(new_params)
        user.deliver_invite_to_account!(new_params)
        user.deliver_invite_to_account_notify_admin!(new_params)
      end
    end
  end

  def user_exists_for_account?(user_email, target_ssl = nil)
    ssl = target_ssl.nil? ? ssl_account : target_ssl
    user = User.get_user_by_email(user_email)
    user && SslAccountUser.where(user_id: user, ssl_account_id: ssl).any?
  end

  def remove_user_from_account(account, current_user)
    assignments.where(ssl_account_id: account).delete_all
    ssl = ssl_account_users.where(ssl_account_id: account).delete_all
    if ssl.positive?
      deliver_removed_from_account!(account, current_user)
      deliver_removed_from_account_notify_admin!(account, current_user) unless current_user.is_system_admins?
      update_default_ssl_account(account)
    end
  end

  def leave_team(remove_ssl)
    unless remove_ssl.get_account_owner == self
      ssl = ssl_account_users.where(ssl_account_id: remove_ssl).delete_all
      assignments.where(ssl_account_id: remove_ssl).delete_all
    end
    if ssl&.positive?
      update_default_ssl_account(remove_ssl)
      deliver_leave_team!(remove_ssl)
      Assignment.where( # notify team owner and users_manager(s)
        ssl_account_id: remove_ssl,
        role_id: Role.get_role_ids([Role::OWNER, Role::USERS_MANAGER])
      ).map(&:user).uniq.compact.each do |notify|
        deliver_leave_team_notify_admins!(notify, remove_ssl)
      end
    end
  end

  def update_default_ssl_account(remove_ssl)
    if default_ssl_account == remove_ssl.id
      if main_ssl_account != remove_ssl.id
        update(default_ssl_account: main_ssl_account)
      else
        ssl = get_first_approved_acct
        update(default_ssl_account: ssl.id, main_ssl_account: ssl.id)
      end
    end
    update(main_ssl_account: default_ssl_account) if main_ssl_account == remove_ssl.id
  end

  def self.get_user_by_email(email)
    current_user = User.where('lower(email) = ?', email.strip.downcase)
    current_user.any? ? current_user.first : nil
  end

  def manageable_users
    ssl_account.cached_users
  end

  def manageable_acs
    ssl_account.api_credentials
  end

  def has_role?(role)
    roles.map { |r| r.name.downcase }.include?(role.to_s)
  end

  def active?
    active
  end

  def is_disabled?(target_ssl = nil)
    Rails.cache.fetch("#{cache_key}/is_disabled/#{target_ssl.try(:cache_key)}") do
      ssl = target_ssl || ssl_account
      return true if ssl.nil?

      ssl_account_users.where(ssl_account_id: ssl.id).map(&:user_enabled).include?(false)
    end
  end

  def is_admin_disabled?
    Rails.cache.fetch("#{cache_key}/is_admin_disabled}") do
      !ssl_account_users.map(&:user_enabled).include?(true)
    end
  end

  def browsing_history(l_bound = nil, h_bound = nil, sort = 'asc')
    l_bound = '01/01/2000' if l_bound.blank?
    s = %r{/}.match?(l_bound) ? '%m/%d/%Y' : '%m-%d-%Y'
    start = Date.strptime l_bound, s
    finish =
      if h_bound.blank?
        DateTime.now
      elsif h_bound.is_a?(String)
        f = %r{/}.match?(h_bound) ? '%m/%d/%Y' : '%m-%d-%Y'
        Date.strptime h_bound, f
      else
        h_bound.to_datetime
      end
    count = 0
    visitor_tokens.map do |vt|
      ["route #{count += 1}"] +
        vt.trackings.order('created_at ' + sort).where { created_at >> (start..finish) }.map { |t| "from #{t.referer.url.presence || 'unknown'} to #{t.tracked_url.url} at #{t.created_at}" }.uniq
    end
  end

  # find user with no ssl_account
  def ssl_account_orphans
    User.where { ssl_account_id.not_in SslAccount.all }
  end

  # we need to make sure that either a password or openid gets set
  # when the user activates his account
  def has_no_credentials?
    crypted_password.blank? # && self.openid_identifier.blank?
  end

  # ...
  # now let's define a couple of methods in the user model. The first
  # will take care of setting any data that you want to happen at signup
  # (aka before activation)
  def signup!(params)
    assign_roles(params)
    self.login = params[:user][:login] if login.blank?
    self.email = params[:user][:email]

    # new logic for auto activation account by passing password on Signup page.
    if Settings.require_signup_password
      self.password = params[:user][:password] if params[:user][:password].present?
      self.password_confirmation = params[:user][:password_confirmation] if params[:user][:password_confirmation].present?
      self.active = true if params[:user][:password].present?
    end

    save_without_session_maintenance
  end

  def assign_roles(params)
    role_ids = params[:user][:role_ids]
    cur_account_id = params[:user][:ssl_account_id]
    new_role_ids = role_ids.compact.reject(&:blank?) unless role_ids.nil? || cur_account_id.nil?
    if new_role_ids.present?
      current_account = SslAccount.find cur_account_id
      current_role_ids = roles_for_account current_account
      new_role_ids -= current_role_ids
      set_roles_for_account(current_account, new_role_ids.uniq)
    end
  end

  def remove_roles(params, inverse = false)
    new_role_ids       = params[:user][:role_ids].compact.reject(&:blank?).map(&:to_i)
    current_role_ids   = roles_for_account(SslAccount.find(params[:user][:ssl_account_id]))
    removable_role_ids = inverse ? new_role_ids : current_role_ids - new_role_ids

    assignments.where(
      role_id: removable_role_ids,
      ssl_account_id: params[:user][:ssl_account_id]
    ).destroy_all
  end

  class << self
    extend Memoist
    def roles_list_for_user(user, exclude_roles = [])
      exclude_roles ||= []
      exclude_roles << Role.where.not(id: Role.get_select_ids_for_owner).map(&:id).uniq unless user.is_system_admins?
      exclude_roles.any? ? Role.where.not(id: exclude_roles.flatten) : Role.all
    end
    memoize :roles_list_for_user

    def get_user_accounts_roles(user)
      # e.g.: {17198:[4], 29:[17, 18], 15:[17, 18, 19, 20]}
      Rails.cache.fetch("#{user.cache_key}/get_user_accounts_roles") do
        user.ssl_accounts.each_with_object({}) do |s, all|
          all[s.id] = user.assignments.where(ssl_account_id: s.id).pluck(:role_id).uniq
        end
      end
    end
    memoize :get_user_accounts_roles

    def user_account_roles(user)
      ids = get_user_accounts_roles(user).uniq
      Role.where(id: ids)
    end
    memoize :user_account_roles

    def get_user_accounts_roles_names(user)
      # e.g.: {'team_1': ['owner'], 'team_2': ['account_admin', 'installer']}
      Rails.cache.fetch("#{user.cache_key}/get_user_accounts_roles_names") do
        user.ssl_accounts.each_with_object({}) do |s, all|
          all[s.get_team_name] = user.assignments.where(ssl_account_id: s.id).map(&:role).uniq.map(&:name)
          all
        end
      end
    end
    memoize :get_user_accounts_roles_names

    def total_teams_owned(user_id)
      User.find(user_id).assignments.includes(:ssl_account).where(role_id: Role.get_owner_id).map(&:ssl_account).uniq.compact
    end
    memoize :total_teams_owned
  end

  # the second will take care of setting any data that you want to happen
  # at activation. at the very least this will be setting active to true
  # and setting a pass, openid, or both.
  def activate!(params)
    self.active = true
    self.login = params[:user][:login] if params[:user][:login]
    self.password = params[:user][:password]
    self.password_confirmation = params[:user][:password_confirmation]
    # self.openid_identifier = params[:user][:openid_identifier]
    save
  end

  def signed_certificates
    SignedCertificate.with_permissions_to(:update)
  end

  def referer_urls
    visitor_tokens.map { |v| v.trackings.non_ssl_com_referer }.flatten.map { |t| t.referer.url }
  end

  def roles_humanize(target_account = nil)
    Role.where(id: roles_for_account(target_account || ssl_account)).map { |role| role.name.humanize(capitalize: false) }
  end

  def role_symbols(target_account = nil)
    sa = target_account || ssl_account
    return [] if sa.blank?

    Rails.cache.fetch("#{cache_key}/role_symbols/#{sa.cache_key}") do
      Role.where(id: roles_for_account(sa)).map { |role| role.name.underscore.to_sym }
    end
  end
  memoize :role_symbols

  def role_symbols_all_accounts
    roles.map { |role| role.name.underscore.to_sym }
  end

  def certificate_order_by_ref(ref)
    CertificateOrder.unscoped.includes(:certificate_contents).find(
      Rails.cache.fetch("#{cache_key}/certificate_order_id/#{ref}") do
        co = CertificateOrder.unscoped do
          (is_system_admins? ?
        CertificateOrder : certificate_orders).find_by(ref: ref)
        end
        co.id if co.present?
      end
    )
  end

  # check for any SslAccount records do not have roles, users or an owner
  # check for any User record that do not have a role for a given SslAccount
  def self.integrity_check(fix = nil)
    # find SslAccount records with no users
    no_users = SslAccount.joins { ssl_account_users.outer }.where { ssl_account_users.ssl_account_id == nil }
    # verify users do not exist
    ap no_users.map(&:users).flatten.compact
    no_users.delete if fix
    # find User records with no ssl_accounts
    no_ssl_accounts = User.unscoped.joins { ssl_account_users.outer }.where { ssl_account_users.user_id == nil }
    ap no_ssl_accounts.map(&:ssl_accounts).flatten.compact
    # find any SslAccount record without a role that belongs to a User
    Assignment.joins { user }.joins { user.ssl_accounts }.where { ssl_account_id == nil }.count
    # How many SslAccounts that do not have any role
    SslAccount.joins { assignments.outer }.where { assignments.ssl_account_id == nil }.count
    # How many SslAccounts that have the owner role
    SslAccount.joins { assignments }.where { assignments.role_id == 4 }.count
  end

  def can_manage_certificates?
    is_system_admins? && is_ra_admin?
  end

  def can_perform_accounting?
    is_billing? || is_owner? || is_account_admin?
  end

  def is_admin?
    role_symbols.include? Role::SYS_ADMIN.to_sym
  end

  def is_super_user?
    role_symbols.include? Role::SUPER_USER.to_sym
  end

  def is_ra_admin?
    role_symbols.include? Role::RA_ADMIN.to_sym
  end

  def is_owner?(target_account = nil)
    role_symbols(target_account).include? Role::OWNER.to_sym
  end

  def is_account_admin?
    role_symbols.include? Role::ACCOUNT_ADMIN.to_sym
  end

  def is_standard?
    (role_symbols & [Role::OWNER.to_sym, Role::ACCOUNT_ADMIN.to_sym]).any?
  end

  def is_reseller?(target_account = nil)
    role_symbols(target_account).include? Role::RESELLER.to_sym
  end

  def is_billing?
    role_symbols.include? Role::BILLING.to_sym
  end

  def is_billing_only?
    role_symbols.include?(Role::BILLING.to_sym) && role_symbols.count == 1
  end

  def is_installer?
    role_symbols.include? Role::INSTALLER.to_sym
  end

  def is_validations?
    role_symbols.include? Role::VALIDATIONS.to_sym
  end

  def is_validations_only?
    role_symbols.include?(Role::VALIDATIONS.to_sym) && role_symbols.count == 1
  end

  def is_validations_and_billing_only?
    role_symbols.include?(Role::VALIDATIONS.to_sym) &&
      role_symbols.include?(Role::BILLING.to_sym) &&
      role_symbols.count == 2
  end

  def is_individual_certificate?
    role_symbols.include? Role::INDIVIDUAL_CERTIFICATE.to_sym
  end

  def is_individual_certificate_only?
    role_symbols == [Role::INDIVIDUAL_CERTIFICATE.to_sym]
  end

  def is_users_manager?
    role_symbols.include? Role::USERS_MANAGER.to_sym
  end

  def is_affiliate?
    ssl_account && !!ssl_account.affiliate
  end

  def is_system_admins?
    is_super_user? || is_admin?
  end

  # if user has duplicate v2 users and is not consolidated
  # then find the duplicate v2 user matching the username
  # and copy it's username, crypted password, and email in the respective users fields
  # and mark the user consolidated
  def self.duplicate_logins(obj)
    if obj.is_a? User
      DuplicateV2User.where(login: obj.login)
    else # assume string
      DuplicateV2User.find_all_by_login(obj)
    end
  end

  # TODO: this is unfinished, going to instead email all
  # duplicate_v2_users emails the corresponding consolidated username
  def self.consolidate_login(obj, password)
    user = duplicate_logins(obj).last.user
    dupes = duplicate_logins(obj).last.user.duplicate_v2_users
    matched = dupes.each do |dupe|
      break dupe if LegacySslMd5.matches?(dupe.password, password)
    end
    if matched
      user.login = obj
      user.crypted_password = matched.password
    end
  end

  def elevate_role(role_symbol)
    unless roles.map(&:name).include?(role_symbol)
      roles << Role.find_by(name: role_symbol)
      assignments << Assignment.new(ssl_account_id: ssl_account.id, role_id: Role.find_by(name: role_symbol).id)
    end
  end

  def remove_admin
    sysadmin_roles = get_roles_by_name(Role::SYS_ADMIN)
    return unless sysadmin_roles

    sysadmin_roles.each do |r|
      if r.ssl_account_id.nil?
        r.delete
      else
        update_account_role(r.ssl_account_id, Role::SYS_ADMIN, Role::OWNER) unless duplicate_role?(Role::OWNER, r.ssl_account_id)
        r.delete if duplicate_role?(Role::OWNER, r.ssl_account_id)
      end
    end
  end

  #
  # User invite and approval token management
  #

  def set_status_for_account(status_type, target_ssl = nil)
    ssl = target_ssl.nil? ? ssl_account : target_ssl
    owner_id = Role.get_owner_id

    target_ssl = if roles_for_account(ssl).include?(owner_id)
                   SslAccountUser.where(ssl_account_id: ssl.id) # if owner, disable access to this ssl account for all associated users
                 else
                   ssl_account_users.where(ssl_account_id: ssl.id)
                 end
    target_ssl.update_all(user_enabled: (status_type == :enabled))
    clear_def_ssl_for_users(target_ssl)
  end

  def set_status_all_accounts(status_type)
    ssl_accounts.each { |target_ssl| set_status_for_account(status_type, target_ssl) } if status_type
  end

  def clear_def_ssl_for_users(target_ssl_account_users)
    # if any user in target_ssl_account_users has their default_ssl_account set
    # to ssl_account in target_ssl_account_users, clear user's default_ssl_account
    # since it's disabled
    users_clear_ssl = target_ssl_account_users.map(&:user).uniq.flatten.compact.keep_if { |u| target_ssl_account_users.map(&:ssl_account_id).include?(u.default_ssl_account) }.map(&:id)
    User.where(id: users_clear_ssl).update_all(default_ssl_account: nil) if users_clear_ssl.any?
  end

  def authenticated_avatar_url(options = { style: :standard })
    expires_in = 10.minutes
    options.reverse_merge! expires_in: expires_in, use_ssl: true
    avatar.s3_object(options[:style]).presigned_url(:get, secure: true, expires_in: expires_in).to_s
  end

  # 2FA

  ##
  # Check if user is registered with authy and
  # if the authy cellphone is the same as user's phone
  def phone_verified?
    return false unless authy_user

    authy_user_result = Authy::API.user_status(id: authy_user)
    return false unless authy_user_result['success'] == true

    user_country_code = phone_prefix
    authy_user_result['status']['phone_number']&.last(4) == phone&.last(4) && authy_user_result['status']['country_code'].to_s == user_country_code.to_s
  end

  ##
  # Checks if the user needs to verify phone via OTP
  # Verification is needed when there is a change for user's phone and/or phone_prefix
  # For pre-existing phone details (no changes to phone/phone_prefix) that are not verified
  # register user with authy and verify phone, so that 2FA with OTP is possible
  def requires_phone_verification?
    phone_changed? || phone_prefix_changed? || !phone_verified?
  end

  private

  # https://github.com/binarylogic/authlogic/issues/81
  def should_record_timestamps?
    changed_keys = changes.keys - %w[last_request_at perishable_token updated_at created_at]
    changed_keys.present? && super
  end

  # https://github.com/binarylogic/authlogic/issues/485
  def should_reset_perishable_token
    reset_perishable_token if changed? && changed_attributes.keys != ['last_request_at']
  end

  def self_or_other(user_id)
    user_id ? User.find_by(id: user_id) : self
  end

  def approve_account(params)
    ssl = get_ssl_acct_user_for_approval(params)
    ssl&.update(approved: true, token_expires: nil, approval_token: nil)
    ssl
  end

  def generate_approval_token
    OAuth::Helper.generate_key(40)[0, 40]
  end

  def get_ssl_acct_user_for_approval(params)
    SslAccountUser.where(
      user_id: (params[:id].nil? ? id : params[:id]),
      ssl_account_id: params[:ssl_account_id]
    ).first
  end

  def get_first_approved_acct
    sa_id = Rails.cache.fetch("#{cache_key}/get_first_approved_acct") do
      ssl = ssl_account_users.where(approved: true, user_enabled: true)
      ssl.any? ? ssl.first.ssl_account_id : nil
    end
    ssl_accounts.find_by(id: sa_id) if sa_id
  end

  def self.change_login(old, new)
    # requires SQL statement to change login
    User.where('login LIKE ?', old).update_all(login: new)
  end

  def validate_password?
    (!new_record? || (new_record? && crypted_password)) && require_password?
  end
end
