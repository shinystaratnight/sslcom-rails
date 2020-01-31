class User < ApplicationRecord
  extend Memoist
  # include V2MigrationProgressAddon
  include UserMessageable

  mount_uploader :avatar, AvatarUploader

  swagger_schema :CreateUser do
    key :required, [:login, :email, :password]
    property :account_key do
      key :type, :string
    end
    property :secret_key do
      key :type, :string
    end
    property :status do
      key :type, :string
    end
    property :user_url do
      key :type, :string
    end
  end

  OWNED_MAX_TEAMS = 3
  PASSWORD_SPECIAL_CHARS = '~`!@#\$%^&*()-+={}[]|;:"<>,./?'

  has_many  :u2fs
  has_many  :assignments, dependent: :destroy
  has_many  :visitor_tokens
  has_many  :surls
  has_many  :roles, :through => :assignments
  has_many  :permissions, :through => :roles
  has_many  :legacy_v2_user_mappings, :as=>:user_mappable
  has_many  :duplicate_v2_users
  has_many  :other_party_requests
  has_many  :client_applications
  has_many  :owned_system_audits, as: :owner, class_name: "SystemAudit"
  has_many  :target_system_audits, as: :target, class_name: "SystemAudit"
  has_many  :tokens, ->{order("authorized_at desc").includes(:client_application)}, :class_name => "OauthToken"
  has_many  :ssl_account_users, dependent: :destroy
  has_many  :ssl_accounts, through: :ssl_account_users
  has_many  :certificate_orders, through: :ssl_accounts
  has_many  :orders, through: :ssl_accounts
  has_many  :validation_histories, through: :certificate_orders
  has_many  :validations, through: :certificate_orders
  has_many  :approved_ssl_account_users, ->{where{(approved == true) & (user_enabled == true)}},
            dependent: :destroy, class_name: "SslAccountUser"
  has_many  :approved_ssl_accounts,
            foreign_key: :ssl_account_id, source: "ssl_account", through: :approved_ssl_account_users
  has_many  :approved_teams,
            foreign_key: :ssl_account_id, source: "ssl_account", through: :approved_ssl_account_users
  has_many  :refunds
  has_many  :discounts, as: :benefactor, dependent: :destroy
  has_one   :shopping_cart
  has_and_belongs_to_many :user_groups
  has_many  :notification_groups, through: :ssl_accounts
  has_many  :certificate_order_tokens

  preference  :managed_certificate_row_count, :string, :default => "10"
  preference  :registered_agent_row_count, :string, :default => "10"
  preference  :cert_order_row_count, :string, :default => "10"
  preference  :order_row_count, :string, :default => "10"
  preference  :cdn_row_count, :string, :default => "10"
  preference  :user_row_count, :string, :default => "10"
  preference  :note_group_row_count, :string, :default => "10"
  preference  :scan_log_row_count, :string, :default => "10"
  preference  :domain_row_count, :string, :default => "10"
  preference  :domain_csr_row_count, :string, :default => "10"
  preference  :team_row_count, :string, :default => "10"
  preference  :validate_row_count, :string, :default => "10"
  preference  :managed_csr_row_count, :string, :default => "10"

  attr_accessor :changing_password, :admin_update, :role_ids, :role_change_type
  attr_accessible :login, :email, :password, :password_confirmation,
    :openid_identifier, :status, :assignments_attributes, :first_name, :last_name,
    :default_ssl_account, :ssl_account_id, :role_ids, :role_change_type,
    :main_ssl_account, :max_teams, :persist_notice
  validates :email, email: true, uniqueness: true, #TODO look at impact on checkout
    format: {with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, on: :create}
  validates :password, format: {
    with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[\W]).{8,}\z/, if: :validate_password?,
    message: "must be at least 8 characters long and include at least 1 of each of the following: uppercase, lowercase, number and special character such as #{User::PASSWORD_SPECIAL_CHARS}"
  }
  accepts_nested_attributes_for :assignments

  acts_as_messageable

  acts_as_authentic do |c|
    c.logged_in_timeout = 30.minutes
    c.validate_email_field = false
    c.session_ids = [nil, :shadow]
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
    c.validates_length_of_password_field_options =
      {:on => :update, :minimum => 8,
      :if => '(has_no_credentials? && !admin_update) || changing_password'}
    c.validates_length_of_password_confirmation_field_options =
      {:on => :update, :minimum => 8,
      :if => '(has_no_credentials? && !admin_update) || changing_password'}
  end

  before_save :should_reset_perishable_token

  before_create do |u|
    u.status='enabled'
    u.max_teams = OWNED_MAX_TEAMS unless u.max_teams
  end

  default_scope        {where{status << ['disabled']}.order("users.created_at desc")}
  scope :with_role, -> (role){joins(:roles).where('lower(roles.name) LIKE (?)',
                        "%#{role.downcase.strip}%")}
  scope :search,    -> (term){joins{ssl_accounts.api_credentials}.where{
                        (login =~ "%#{term}%") |
                        (email =~ "%#{term}%") |
                        (last_login_ip =~ "%#{term}%") |
                        (current_login_ip =~ "%#{term}%") |
                        (ssl_accounts.api_credentials.account_key =~ "%#{term}%") |
                        (ssl_accounts.api_credentials.secret_key =~ "%#{term}%") |
                        (ssl_accounts.acct_number =~ "%#{term}%")}.uniq}

  scope :search_sys_admin, ->{ joins{ roles }.where{ roles.name == Role::SYS_ADMIN } }

  scope :search_super_user, -> {joins{roles}.where{roles.name == Role::SUPER_USER}}

  def ssl_account(default_team=nil)
    SslAccount.find_by_id(Rails.cache.fetch("#{cache_key}/ssl_account/#{default_team.is_a?(Symbol) ? default_team.to_s : default_team.try(:cache_key)}") do
      default_ssl = default_ssl_account && is_approved_account?(default_ssl_account)
      main_ssl    = main_ssl_account && is_approved_account?(main_ssl_account)

      # Retrieve team that was manually set as default in Teams by user
      break main_ssl_account if (default_team && main_ssl)

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
  memoize "is_approved_account?".to_sym

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
    assignments.where(role_id: [Role.get_owner_id, Role.get_account_admin_id], ssl_account_id: ssl_account.id).size > 0
  end

  def role_symbols_archived_team(ssl_account)
    assignments.includes(:role).where(ssl_account_id: ssl_account.id).map{|assign| assign.role.name.to_sym}.uniq.compact
  end

  def is_first_approved_acct?(ssl_account)
    ssl_account == get_first_approved_acct
  end

  def owned_ssl_account
    total_teams_owned.first
  end

  def team_status(team)
    ssl    = ssl_account_users.where(ssl_account_id: team.id).uniq.compact.first
    if ssl
      status = :accepted if active && ssl.approved
      status = :declined if ssl.declined_at || (!ssl.approved && ssl.token_expires.nil? && ssl.approval_token.nil?)
      status = :expired  if ssl.token_expires && (status != :declined) && (ssl.token_expires < DateTime.now)
      status = :pending  if !active && (status != :declined)
      status = :pending  if active && (!ssl.approved && ssl.token_expires && ssl.approval_token) && (ssl.token_expires > DateTime.now)
    end
    status
  end

  def is_duo_required?
    is_super_user?
  end

  def is_passed_2fa(session_duo)
    status = false
    if self.is_duo_required?
      status = session_duo
    else
      if self.ssl_account&.sec_type == 'duo'
        if Settings.duo_auto_enabled || Settings.duo_custom_enabled
          status = session_duo
        else
          status = true
        end
      else
        status = true
      end
    end
    status
  end

  def get_auto_add_users_teams
    self.ssl_accounts.joins(:assignments).where(
      assignments: {role_id: Role.can_auto_add_users}
    ).uniq.compact
  end

  def get_auto_add_users
    users = User.joins(:ssl_accounts)
      .where(ssl_accounts: {id: get_auto_add_users_teams.map(&:id)})
      .where.not(users: {id: id}).uniq.compact
  end

  def get_auto_add_user_roles(added_user)
    role_ids = added_user.assignments.where(
      ssl_account_id: get_auto_add_users_teams.map(&:id)
    ).pluck(:role_id).uniq

    # If invited user has owner role or reseller role, then replace
    # it with account admin role for the team they're invited to.
    if role_ids.include?(Role.get_owner_id) ||
      role_ids.include?(Role.get_reseller_id)

      # User cannot be account_admin and have other roles.
      role_ids = [Role.get_account_admin_id]
    end
    role_ids.uniq
  end

  def total_teams_owned(user_id=nil)
    user = self_or_other(user_id)
    user.assignments.includes(:ssl_account).where(role_id: Role.get_owner_id).map(&:ssl_account).uniq.compact
  end
  memoize :total_teams_owned

  def total_teams_admin(user_id = nil)
    user = self_or_other(user_id)
    user.assignments.includes(:ssl_account).where(role_id: Role.get_account_admin_id).map(&:ssl_account).uniq.compact
  end
  memoize :total_teams_admin

  def total_teams_can_manage_users(user_id=nil)
    user = self_or_other(user_id)
    user.assignments.includes(:ssl_account).where(role_id: Role.can_manage_users).map(&:ssl_account).uniq.compact
  end
  memoize :total_teams_can_manage_users

  def total_teams_cannot_manage_users(user_id=nil)
    user = self_or_other(user_id)
    user.ssl_accounts - user.assignments.where(role_id: Role.cannot_be_managed)
      .map(&:ssl_account).uniq.compact
  end
  memoize :total_teams_cannot_manage_users

  def max_teams_reached?(user_id=nil)
    user = self_or_other(user_id)
    total_teams_owned(user.id).count >= user.max_teams
  end

  def set_default_team(ssl_account)
    update(main_ssl_account: ssl_account.id) if ssl_accounts.include?(ssl_account)
  end

  def can_manage_team_users?(target_ssl=nil)
    assignments.where(
      ssl_account_id: (target_ssl.nil? ? ssl_account : target_ssl).id,
      role_id: Role.can_manage_users
    ).any?
  end

  def self.find_non_owners
     [].tap do |orphans|
      find_each do |u|
        orphans << u if u.owned_ssl_account.blank?
      end
    end
  end

  def create_ssl_account(role_ids=nil, attr={})
    self.save if self.new_record?
    new_ssl_account = SslAccount.create(attr)
    ssl_accounts << new_ssl_account
    set_roles_for_account(new_ssl_account, role_ids) if (role_ids && role_ids.length > 0)
    set_default_ssl_account(new_ssl_account) unless default_ssl_account
    approve_account(ssl_account_id: new_ssl_account.id)
    new_ssl_account
  end

  def set_default_ssl_account(account)
    account = account.is_a?(SslAccount) ? account.id : account
    update_attribute(:default_ssl_account, account)
  end

  def clear_default_ssl_account
    update_attribute(:default_ssl_account, nil)
  end

  def set_roles_for_account(account, role_ids)
    if account && ssl_accounts.include?(account) && role_ids.count > 0
      role_ids.each do |role|
        Assignment.find_or_create_by(
          user_id:        id,
          role_id:        role,
          ssl_account_id: account.id
        )
      end
    end
  end

  def roles_for_account(target_ssl=nil)
    ssl = target_ssl.nil? ? ssl_account : target_ssl

    if ssl_accounts.include?(ssl)
      assignments.where(ssl_account_id: ssl).pluck(:role_id).uniq
    else
      []
    end
  end
  memoize :roles_for_account

  def get_roles_by_name(role_name)
      role_id = Role.get_role_id(role_name)
      role_id ? assignments.where(role_id: role_id) : []
  end

  def update_account_role(account, old_role, new_role)
    old_role = assignments.where(
      ssl_account_id: account, role_id: Role.get_role_id(old_role)
    ).first
    unless duplicate_role?(new_role, account)
      old_role.update(role_id: Role.get_role_id(new_role)) if old_role
    end
  end

  def duplicate_role?(role, target_ssl=nil)
    assignments.where(
        ssl_account_id: (target_ssl.nil? ? ssl_account : target_ssl).id,
        role_id:        (role.is_a?(String) ? Role.get_role_id(role): Role.find(role))
    ).any?
  end

  def invite_user_to_account!(params)
    user_exists = User.get_user_by_email(params[:user][:email])
    user_exists ? user_exists : invite_new_user(params)
  end

  def invite_new_user(params)
    if params[:deliver_invite]
      User.get_user_by_email(params[:user][:email])
        .deliver_signup_invitation!(params[:from_user], params[:root_url], params[:invited_teams])
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
    email       = params[:user][:email] if params[:user]
    ssl_acct_id = (params[:user] && params[:user][:ssl_account_id]) || params[:ssl_account_id]
    user        = email ? User.get_user_by_email(email) : self
    new_params  = params.merge(ssl_account_id: ssl_acct_id, skip_match: true, from_user: params[:from_user])

    if user.ssl_accounts.map(&:id).include? ssl_acct_id.to_i
      user.set_approval_token(new_params)
      if user.approval_token_valid?(new_params)
        user.deliver_invite_to_account!(new_params)
        user.deliver_invite_to_account_notify_admin!(new_params)
      end
    end
  end

  def user_exists_for_account?(user_email, target_ssl=nil)
    ssl = target_ssl.nil? ? ssl_account : target_ssl
    user = User.get_user_by_email(user_email)
    user && SslAccountUser.where(user_id: user, ssl_account_id: ssl).any?
  end

  def remove_user_from_account(account, current_user)
    assignments.where(ssl_account_id: account).delete_all
    ssl = ssl_account_users.where(ssl_account_id: account).delete_all
    if ssl > 0
      deliver_removed_from_account!(account, current_user)
      unless current_user.is_system_admins?
        deliver_removed_from_account_notify_admin!(account, current_user)
      end
      update_default_ssl_account(account)
    end
  end

  def leave_team(remove_ssl)
    unless remove_ssl.get_account_owner == self
      ssl = ssl_account_users.where(ssl_account_id: remove_ssl).delete_all
      assignments.where(ssl_account_id: remove_ssl).delete_all
    end
    if ssl && ssl > 0
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
        update_attributes(default_ssl_account: ssl.id, main_ssl_account: ssl.id)
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
    roles.map{|r|r.name.downcase}.include?(role.to_s)
  end

  def active?
    active
  end

  def is_disabled?(target_ssl=nil)
    Rails.cache.fetch("#{cache_key}/is_disabled/#{target_ssl.try(:cache_key)}") do
      ssl = target_ssl || ssl_account
      return true if ssl.nil?
      ssl_account_users.where(ssl_account_id: ssl.id)
          .map(&:user_enabled).include?(false)
    end
  end

  def is_admin_disabled?
    Rails.cache.fetch("#{cache_key}/is_admin_disabled}") do
      !ssl_account_users.map(&:user_enabled).include?(true)
    end
  end

  def deliver_activation_confirmation_by_sysadmin!(password)
    reset_perishable_token!
    UserNotifier.activation_confirmation_by_sysadmin(self, password).deliver
  end

  def deliver_auto_activation_confirmation!
    reset_perishable_token!
    UserNotifier.auto_activation_confirmation(self).deliver
  end

  def deliver_activation_instructions!
    reset_perishable_token!
    UserNotifier.activation_instructions(self).deliver
  end

  def deliver_activation_confirmation!
    reset_perishable_token!
    UserNotifier.activation_confirmation(self).deliver
  end

  def deliver_signup_invitation!(current_user, root_url, invited_teams)
    reset_perishable_token!
    UserNotifier.signup_invitation(self, current_user, root_url, invited_teams).deliver
  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    UserNotifier.password_reset_instructions(self).deliver
  end

  def deliver_username_reminder!
    UserNotifier.username_reminder(self).deliver
  end

  def deliver_password_changed!
    UserNotifier.password_changed(self).deliver
  end

  def deliver_email_changed!(address=self.email)
    UserNotifier.email_changed(self, address).deliver
  end

  def deliver_invite_to_account!(params)
    UserNotifier.invite_to_account(self, params[:from_user], params[:ssl_account_id]).deliver
  end

  def deliver_invite_to_account_notify_admin!(params)
    UserNotifier.invite_to_account_notify_admin(self, params[:from_user], params[:ssl_account_id]).deliver
  end

  def deliver_removed_from_account!(account, current_user)
    UserNotifier.removed_from_account(self, account, current_user).deliver
  end

  def deliver_removed_from_account_notify_admin!(account, current_user)
    UserNotifier.removed_from_account_notify_admin(self, account, current_user).deliver
  end

  def deliver_leave_team!(account)
    UserNotifier.leave_team(self, account).deliver
  end

  def deliver_leave_team_notify_admins!(notify_user, account)
    UserNotifier.leave_team_notify_admins(self, notify_user, account).deliver
  end

  def deliver_invite_to_account_accepted!(account, for_admin=nil)
    UserNotifier.invite_to_account_accepted(self, account, for_admin).deliver
  end

  def deliver_invite_to_account_disabled!(account, current_user)
    UserNotifier.invite_to_account_disabled(self, account, current_user).deliver
  end

  def deliver_ssl_cert_private_key!(resource_id, host_name, custom_domain_id)
    UserNotifier.ssl_cert_private_key(self, resource_id, host_name, custom_domain_id).deliver
  end

  def deliver_generate_install_ssl!(resource_id, host_name, to_address)
    UserNotifier.generate_install_ssl(self, resource_id, host_name, to_address).deliver
  end

  def deliver_register_ssl_manager_to_team!(registered_agent_ref, ssl_account, auto_approve)
    auto_approve ?
        UserNotifier.auto_register_ssl_manager_to_team(self, ssl_account).deliver :
        UserNotifier.register_ssl_manager_to_team(self, registered_agent_ref, ssl_account).deliver
  end

  def browsing_history(l_bound=nil, h_bound=nil, sort="asc")
    l_bound = "01/01/2000" if l_bound.blank?
    s= l_bound =~ /\// ? "%m/%d/%Y" : "%m-%d-%Y"
    start = Date.strptime l_bound, s
    finish =
        if(h_bound.blank?)
          DateTime.now
        elsif h_bound.is_a?(String)
          f= h_bound =~ /\// ? "%m/%d/%Y" : "%m-%d-%Y"
          Date.strptime h_bound, f
        else
          h_bound.to_datetime
        end
    count=0
    visitor_tokens.map do |vt|
      ["route #{count+=1}"]+
      vt.trackings.order("created_at "+sort).where{created_at >> (start..finish)}.map{|t| "from #{t.referer.url.blank? ? "unknown" : t.referer.url} to #{t.tracked_url.url} at #{t.created_at}"}.uniq
    end
  end

  # find user with no ssl_account
  def ssl_account_orphans
    User.where{ssl_account_id.not_in SslAccount.all}
  end

  # we need to make sure that either a password or openid gets set
  # when the user activates his account
  def has_no_credentials?
    self.crypted_password.blank? #&& self.openid_identifier.blank?
  end

  # ...
  # now let's define a couple of methods in the user model. The first
  # will take care of setting any data that you want to happen at signup
  # (aka before activation)
  def signup!(params)
    assign_roles(params)
    self.login = params[:user][:login] if login.blank?
    self.email = params[:user][:email]

    # TODO: New logic for auto activation account by passing password on Signup page.
    if Settings.require_signup_password
      self.password = params[:user][:password] unless params[:user][:password].blank?
      self.password_confirmation = params[:user][:password_confirmation] unless params[:user][:password_confirmation].blank?
      self.active = true unless params[:user][:password].blank?
    end

    save_without_session_maintenance
  end

  def assign_roles(params)
    role_ids = params[:user][:role_ids]
    cur_account_id = params[:user][:ssl_account_id]
    unless role_ids.nil? || cur_account_id.nil?
      new_role_ids = role_ids.compact.reject{|id| id.blank?}.map(&:to_i)
    end
    if new_role_ids.present?
      current_account  = SslAccount.find cur_account_id
      current_role_ids = roles_for_account current_account
      new_role_ids     = new_role_ids - current_role_ids
      set_roles_for_account(current_account, new_role_ids.uniq)
    end
  end

  def remove_roles(params, inverse=false)
    new_role_ids       = params[:user][:role_ids].compact.reject{|id| id.blank?}.map(&:to_i)
    current_role_ids   = roles_for_account(SslAccount.find(params[:user][:ssl_account_id]))
    removable_role_ids = inverse ? new_role_ids : current_role_ids - new_role_ids

    assignments.where(
      role_id:        removable_role_ids,
      ssl_account_id: params[:user][:ssl_account_id]
    ).destroy_all
  end

  class << self
    extend Memoist
    def roles_list_for_user(user, exclude_roles=nil)
      exclude_roles ||= []
      unless user.is_system_admins?
        exclude_roles << Role.where.not(id: Role.get_select_ids_for_owner).map(&:id).uniq
      end
      exclude_roles.any? ? Role.where.not(id: exclude_roles.flatten) : Role.all
    end
    memoize :roles_list_for_user

    def get_user_accounts_roles(user)
      # e.g.: {17198:[4], 29:[17, 18], 15:[17, 18, 19, 20]}
      Rails.cache.fetch("#{user.cache_key}/get_user_accounts_roles") do
        user.ssl_accounts.inject({}) do |all, s|
          all[s.id] = user.assignments.where(ssl_account_id: s.id).pluck(:role_id).uniq
          all
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
    #self.openid_identifier = params[:user][:openid_identifier]
    save
  end

  def signed_certificates
    SignedCertificate.with_permissions_to(:update)
  end

  def referer_urls
    visitor_tokens.map{|v|v.trackings.non_ssl_com_referer}.flatten.map{|t|t.referer.url}
  end

  def roles_humanize(target_account=nil)
    Role.where(id: roles_for_account(target_account || ssl_account))
      .map{|role| role.name.humanize(capitalize: false)}
  end

  def role_symbols(target_account=nil)
    sa = target_account || ssl_account
    return [] if sa.blank?

    Rails.cache.fetch("#{cache_key}/role_symbols/#{sa.cache_key}") do
      Role.where(id: roles_for_account(sa)).map{|role| role.name.underscore.to_sym}
    end
  end
  memoize :role_symbols

  def role_symbols_all_accounts
    roles.map{|role| role.name.underscore.to_sym}
  end

  def certificate_order_by_ref(ref)
    CertificateOrder.unscoped.includes(:certificate_contents).find(
        Rails.cache.fetch("#{cache_key}/certificate_order_id/#{ref}") do
          co=CertificateOrder.unscoped{(is_system_admins? ?
             CertificateOrder : certificate_orders).find_by_ref(ref)}
          co.id unless co.blank?
        end)
  end

  # check for any SslAccount records do not have roles, users or an owner
  # check for any User record that do not have a role for a given SslAccount
  def self.integrity_check(fix=nil)
    # find SslAccount records with no users
    no_users=SslAccount.joins{ssl_account_users.outer}.where{ssl_account_users.ssl_account_id == nil}
    # verify users do not exist
    ap no_users.map(&:users).flatten.compact
    no_users.delete if fix
    # find User records with no ssl_accounts
    no_ssl_accounts=User.unscoped.joins{ssl_account_users.outer}.where{ssl_account_users.user_id == nil}
    ap no_ssl_accounts.map(&:ssl_accounts).flatten.compact
    # find any SslAccount record without a role that belongs to a User
    Assignment.joins{user}.joins{user.ssl_accounts}.where{ssl_account_id == nil}.count
    # How many SslAccounts that do not have any role
    SslAccount.joins{assignments.outer}.where{assignments.ssl_account_id==nil}.count
    # How many SslAccounts that have the owner role
    SslAccount.joins{assignments}.where{assignments.role_id==4}.count
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

  def is_owner?(target_account=nil)
    # TODO need to separate out reseller from owner
    role_symbols(target_account) & [Role::OWNER.to_sym,Role::RESELLER.to_sym]
  end

  def is_account_admin?
    role_symbols.include? Role::ACCOUNT_ADMIN.to_sym
  end

  def is_standard?
    (role_symbols & [Role::OWNER.to_sym, Role::ACCOUNT_ADMIN.to_sym]).any?
  end

  def is_reseller?(target_account=nil)
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
    role_symbols==[Role::INDIVIDUAL_CERTIFICATE.to_sym]
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

  #if user has duplicate v2 users and is not consolidated
  #then find the duplicate v2 user matching the username
  #and copy it's username, crypted password, and email in the respective users fields
  #and mark the user consolidated
  def self.duplicate_logins(obj)
    if obj.is_a? User
      DuplicateV2User.where(:login=>obj.login)
    else #assume string
      DuplicateV2User.find_all_by_login(obj)
    end
  end

  #TODO this is unfinished, going to instead email all
  #duplicate_v2_users emails the corresponding consolidated username
  def self.consolidate_login(obj, password)
    user=duplicate_logins(obj).last.user
    dupes=duplicate_logins(obj).last.user.duplicate_v2_users
    matched=dupes.each do |dupe|
      break dupe if (LegacySslMd5.matches? dupe.password, password)
    end
    if matched
      user.login=obj
      user.crypted_password=matched.password
    end
  end

  #temporary function to assist in migration
  if MIGRATING_FROM_LEGACY
    def update_record_without_timestamping
      class << self
        def record_timestamps; false; end
      end

      save(false)

      class << self
        def record_timestamps; super ; end
      end
    end
  end

  def apply_omniauth(omniauth)
    self.email = omniauth['user_info']['email']

    # # Update user info fetching from social network
    # case omniauth['provider']
    # when 'facebook'
    #   # fetch extra user info from facebook
    # when 'twitter'
    #   # fetch extra user info from twitter
    # end
  end

  def make_admin
    unless roles.map(&:name).include?(Role::SYS_ADMIN)
      roles << Role.find_by(name: Role::SYS_ADMIN)
      assignments << Assignment.new(ssl_account_id: ssl_account.id, role_id: Role.find_by(name: Role::SYS_ADMIN).id)
    end
  end

  def remove_admin
    sysadmin_roles = get_roles_by_name(Role::SYS_ADMIN)

    if sysadmin_roles.any?
      sysadmin_roles.each do |r|
        if r.ssl_account_id.nil?
          r.delete
        else
          update_account_role(r.ssl_account_id, Role::SYS_ADMIN, Role::OWNER)
        end
      end
    end
  end

  #
  # User invite and approval token management
  #

  def pending_account_invites?
    ssl_account_users.each do |ssl|
      return true if approval_token_valid?(ssl_account_id: ssl.ssl_account_id, skip_match: true)
    end
    return false
  end

  def get_pending_accounts
    acct_invite = []
    ssl_account_users.each do |ssl|
      params = {ssl_account_id: ssl.ssl_account_id, skip_match: true}
      if approval_token_valid?(params)
        acct_invite << {
          acct_number:    SslAccount.find_by_id(ssl.ssl_account_id).acct_number,
          ssl_account_id: ssl.ssl_account_id,
          approval_token: ssl.approval_token
        }
      end
    end
    acct_invite
  end

  def generate_approval_query(params)
    ssl = get_ssl_acct_user_for_approval(params)
    "?token=#{ssl.approval_token}&ssl_account_id=#{ssl.ssl_account_id}"
  end

  def get_approval_tokens
    ssl_account_users.map(&:approval_token).uniq.compact.flatten
  end

  def approve_invite(params)
    ssl_acct_id = params[:ssl_account_id]
    errors      = []
    if user_approved_invite?(params)
      errors << 'Invite already approved for this account!'
    else
      if approval_token_valid?(params)
        set_approval_token(params.merge(clear: true))
        ssl = approve_account(params)
        if ssl
          deliver_invite_to_account_accepted!(ssl.ssl_account)
          Assignment.where( # notify team owner and users_manager(s)
            ssl_account_id: ssl_acct_id,
            role_id: Role.get_role_ids([Role::OWNER, Role::USERS_MANAGER])
          ).map(&:user).uniq.compact.each do |for_admin|
            deliver_invite_to_account_accepted!(ssl.ssl_account, for_admin)
          end
        end
      else
        errors << 'Invite token is invalid or expired, please contact account admin!'
      end
      unless user_approved_invite?(params)
        errors << 'Something went wrong! Please try again!'
      end
    end
    errors
  end

  def decline_invite(params)
    ssl = get_ssl_acct_user_for_approval(params)
    if ssl
      team = ssl.ssl_account
      SystemAudit.create(
        owner:  self,
        target: team,
        action: 'Declined invitation to team (UsersController#decline_account_invite).',
        notes:  "User #{login} has declined invitation to team #{team.get_team_name} (##{team.acct_number})."
      )
      ssl.update(
        approved:       false,
        token_expires:  nil,
        approval_token: nil,
        declined_at:    DateTime.now
      )
    end
  end

  def approve_all_accounts(log_invite=nil)
    ssl_account_users.update_all(
      approved: true, token_expires: nil, approval_token: nil
    )
    if log_invite
      ssl_ids = assignments.where.not(role_id: Role.cannot_be_invited)
        .map(&:ssl_account).uniq.compact.map(&:id)
      ssl_account_users.where(ssl_account_id: ssl_ids).update_all(invited_at: DateTime.now)
    end
  end

  def approval_token_not_expired?(params)
    user_approved_invite?(params) || approval_token_valid?(params.merge(skip_match: true))
  end

  def approval_token_valid?(params)
    ssl               = get_ssl_acct_user_for_approval(params)
    no_ssl_account    = ssl.nil?
    no_token_stored   = ssl && ssl.approval_token.nil?
    has_stored_token  = ssl && ssl.approval_token
    token_expired     = has_stored_token && DateTime.parse(ssl.token_expires.to_s) <= DateTime.now
    tokens_dont_match = params[:skip_match] ? false : (has_stored_token && ssl.approval_token != params[:token])

    return false if no_ssl_account || no_token_stored || tokens_dont_match || token_expired
    true
  end

  def get_all_approved_accounts
    (self.is_system_admins? ? SslAccount.unscoped : self.approved_ssl_accounts).order("created_at desc")
  end

  def get_all_approved_teams
    (self.is_system_admins? ? SslAccount.unscoped : self.approved_teams).order("created_at desc")
  end

  def user_approved_invite?(params)
    ssl = get_ssl_acct_user_for_approval(params)
    ssl && ssl.approved && ssl.token_expires.nil? && ssl.approval_token.nil?
  end

  def user_declined_invite?(params)
    ssl = get_ssl_acct_user_for_approval(params)
    ssl && !ssl.approved && ssl.token_expires.nil? && ssl.approval_token.nil?
  end

  def resend_invitation_with_token(params)
    errors = []
    invite_existing_user(params)
    unless approval_token_valid?(params.merge(skip_match: true))
      errors << 'Token was not renewed. Please try again'
    end
    errors
  end

  def set_approval_token(params)
    ssl = get_ssl_acct_user_for_approval(params)
    if ssl
      ssl.update(
        approved:       false,
        token_expires:  (params[:clear] ? nil : (DateTime.now + 72.hours)),
        approval_token: (params[:clear] ? nil : generate_approval_token),
        invited_at:     DateTime.now,
        declined_at:    nil
      )
    end
  end

  def set_status_for_account(status_type, target_ssl=nil)
    ssl      = target_ssl.nil? ? ssl_account : target_ssl
    owner_id = Role.get_owner_id

    target_ssl = if roles_for_account(ssl).include?(owner_id)
      # if owner, disable access to this ssl account for all associated users
      SslAccountUser.where(ssl_account_id: ssl.id)
    else
      ssl_account_users.where(ssl_account_id: ssl.id)
    end
    target_ssl.update_all(user_enabled: (status_type == :enabled))
    clear_def_ssl_for_users(target_ssl)
  end

  def set_status_all_accounts(status_type)
    ssl_accounts.each{|target_ssl| set_status_for_account(status_type, target_ssl)} if status_type
  end

  def clear_def_ssl_for_users(target_ssl_account_users)
    # if any user in target_ssl_account_users has their default_ssl_account set
    # to ssl_account in target_ssl_account_users, clear user's default_ssl_account
    # since it's disabled
    users_clear_ssl = target_ssl_account_users.map(&:user).uniq.flatten.compact
      .keep_if{|u| target_ssl_account_users.map(&:ssl_account_id)
      .include?(u.default_ssl_account)}.map(&:id)
    User.where(id: users_clear_ssl).update_all(default_ssl_account: nil) if users_clear_ssl.any?
  end

  private

  # https://github.com/binarylogic/authlogic/issues/81
  def should_record_timestamps?
    changed_keys = self.changes.keys - ["last_request_at", "perishable_token", "updated_at", "created_at"]
    changed_keys.present? && super
  end

  # https://github.com/binarylogic/authlogic/issues/485
  def should_reset_perishable_token
    if changed? && changed_attributes.keys != ['last_request_at']
      reset_perishable_token
    end
  end

  def self_or_other(user_id)
    user = user_id ? User.find_by_id(user_id) : self
  end

  def approve_account(params)
    ssl = get_ssl_acct_user_for_approval(params)
    ssl.update(approved: true, token_expires: nil, approval_token: nil) if ssl
    ssl
  end

  def generate_approval_token
    OAuth::Helper.generate_key(40)[0,40]
  end

  def get_ssl_acct_user_for_approval(params)
    SslAccountUser.where(
      user_id:        (params[:id].nil? ? id : params[:id]),
      ssl_account_id: params[:ssl_account_id]
    ).first
  end

  def get_first_approved_acct
    sa_id=Rails.cache.fetch("#{cache_key}/get_first_approved_acct") do
      ssl = ssl_account_users.where(approved: true, user_enabled: true)
      ssl.any? ? ssl.first.ssl_account_id : nil
    end
    ssl_accounts.find_by_id(sa_id) if sa_id
  end

  def self.change_login(old, new)
    #requires SQL statement to change login
    User.where('login LIKE ?', old).update_all(login: new)
  end

  def validate_password?
    (!new_record? || (new_record? && crypted_password)) && require_password?
  end
end
