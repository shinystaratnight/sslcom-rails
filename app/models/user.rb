class User < ActiveRecord::Base
  include V2MigrationProgressAddon
#  using_access_control

  OWNED_MAX_TEAMS = 5

  has_many  :assignments, dependent: :destroy
  has_many  :visitor_tokens
  has_many  :surls
  has_many  :roles, :through => :assignments
  has_many  :permissions, :through => :roles
  has_many  :legacy_v2_user_mappings, :as=>:user_mappable
  has_many  :duplicate_v2_users
  has_many  :other_party_requests
  has_many  :client_applications
  has_many  :tokens, ->{order("authorized_at desc").includes(:client_application)}, :class_name => "OauthToken"
  has_many  :ssl_account_users, dependent: :destroy
  has_many  :ssl_accounts, through: :ssl_account_users
  has_one   :shopping_cart
  has_and_belongs_to_many :user_groups
  
  attr_accessor :changing_password, :admin_update, :role_ids
  attr_accessible :login, :email, :password, :password_confirmation,
    :openid_identifier, :status, :assignments_attributes, :first_name, :last_name,
    :default_ssl_account, :ssl_account_id, :role_ids, :main_ssl_account, :max_teams
  validates :email, email: true, uniqueness: true #TODO look at impact on checkout
  validates :password, :format =>
      {:with => /\A(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[\W]).{8,}\z/, if: ('!new_record? and require_password?'),
      message: "must be at least 8 characters and include a lowercase, uppercase, and special character such as ~`!@#$%^&*()-_+={}[]|\;:\"<>,./?."}
  accepts_nested_attributes_for :assignments

  acts_as_authentic do |c|
    c.logged_in_timeout = 20.minutes
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

  before_create do |u|
    u.status='enabled'
    u.max_teams = OWNED_MAX_TEAMS unless u.max_teams
  end

  default_scope        {where{status << ['disabled']}.order("created_at desc")}
  scope :with_role, -> (role){joins(:roles).where('lower(roles.name) LIKE (?)',
                        "%#{role.downcase.strip}%")}
  scope :search,    -> (term){joins{ssl_accounts}.where{
                        (login =~ "%#{term}%") |
                        (email =~ "%#{term}%") |
                        (ssl_accounts.acct_number =~ "%#{term}%")}.uniq}

  def ssl_account
    if default_ssl_account and ssl_accounts.find_by(id: default_ssl_account)
      ssl_accounts.find_by id: default_ssl_account
    else
      approved_account = get_first_approved_acct
      set_default_ssl_account(approved_account) if approved_account
      approved_account
    end
  end
  
  def is_main_account?(ssl_account)
    return false if main_ssl_account.nil?
    ssl_account.id == main_ssl_account
  end

  def is_account_owner?(ssl_account)
    total_teams_owned.include?(ssl_account)
  end

  def owned_ssl_account
    assignments.where{role_id = Role.get_account_admin_id}.first.try :ssl_account
  end

  def total_teams_owned(user_id=nil)
    user = user_id ? User.find(user_id) : self
    user.assignments.where(role_id: Role.get_account_admin_id).map(&:ssl_account).uniq.compact
  end

  def max_teams_reached?(user_id=nil)
    user = user_id ? User.find(user_id) : self
    total_teams_owned(user.id).count >= user.max_teams
  end

  def set_default_team(ssl_account)
    update(main_ssl_account: ssl_account.id) if total_teams_owned.include?(ssl_account)
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

  def roles_for_account(account)
    if ssl_accounts.include?(account)
      assignments.where(ssl_account_id: account).pluck(:role_id).uniq
    else
      []  
    end
  end

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

  def duplicate_role?(role_name, account=nil)
    assignments.where(
      ssl_account_id: account, role_id: Role.get_role_id(role_name)
    ).any?
  end

  def invite_user_to_account!(params)
    user_exists = User.get_user_by_email(params[:user][:email])
    user_exists ? user_exists : invite_new_user(params)
  end

  def invite_new_user(params)
    if params[:deliver_invite]
      User.get_user_by_email(params[:user][:email])
        .deliver_signup_invitation!(params[:from_user], params[:root_url])
    else  
      user = User.new(params[:user].merge(login: params[:user][:email]))
      user.signup!(params)
      user.create_ssl_account([Role.get_account_admin_id])
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

  def user_exists_for_account?(user_email)
    user = User.get_user_by_email(user_email)
    user && SslAccountUser.where(user_id: user, ssl_account_id: ssl_account).any?
  end

  def remove_user_from_account(account, current_user)
    Assignment.where(user_id: self, ssl_account_id: account).delete_all
    ssl = SslAccountUser.where(user_id: self, ssl_account_id: account).delete_all
    if ssl > 0
      deliver_removed_from_account!(account, current_user)
      unless current_user.is_system_admins? 
        deliver_removed_from_account_notify_admin!(account, current_user)
      end
      clear_default_ssl_account if default_ssl_account == account.id
    end
  end

  def self.get_user_by_email(email)
    current_user = User.where('lower(email) = ?', email.strip.downcase)
    current_user.any? ? current_user.first : nil
  end

  def manageable_users
    ssl_account.users
  end

  def has_role?(role)
    roles.map{|r|r.name.downcase}.include?(role.to_s)
  end

  def active?
    active
  end

  def is_disabled?(target_ssl=nil)
    ssl = target_ssl.nil? ? ssl_account : target_ssl
    ssl_account_users.where(ssl_account_id: ssl.id)
      .map(&:user_enabled).include?(false)
  end

  def is_admin_disabled?
    !ssl_account_users.map(&:user_enabled).include?(true)
  end

  def deliver_activation_instructions!
    reset_perishable_token!
    UserNotifier.activation_instructions(self).deliver
  end

  def deliver_activation_confirmation!
    reset_perishable_token!
    UserNotifier.activation_confirmation(self).deliver
  end

  def deliver_signup_invitation!(current_user, root_url)
    reset_perishable_token!
    UserNotifier.signup_invitation(self, current_user, root_url).deliver
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
    assign_roles(params, true)
    self.login = params[:user][:login] if login.blank?
    self.email = params[:user][:email]
    save_without_session_maintenance
  end

  def assign_roles(params, signup=false)
    role_ids = params[:user][:role_ids]
    cur_account_id = params[:user][:ssl_account_id]
    unless role_ids.nil? || cur_account_id.nil?
      new_role_ids = role_ids.compact.reject{|id| id.blank?}.map(&:to_i)
    end
    if new_role_ids.present?
      if signup
        acct_admin_role = Role.get_role_id(Role::ACCOUNT_ADMIN)
        new_role_ids    << acct_admin_role unless new_role_ids.include? acct_admin_role
      end
      current_account  = SslAccount.find cur_account_id
      current_role_ids = roles_for_account current_account
      new_role_ids     = new_role_ids - current_role_ids
      set_roles_for_account(current_account, new_role_ids.uniq)
    end
  end

  def remove_roles(params)
    new_role_ids       = params[:user][:role_ids].compact.reject{|id| id.blank?}.map(&:to_i)
    current_role_ids   = roles_for_account(SslAccount.find(params[:user][:ssl_account_id]))
    removable_role_ids = current_role_ids - new_role_ids
    
    assignments.where(
      role_id:        removable_role_ids,
      ssl_account_id: params[:user][:ssl_account_id]
    ).destroy_all
  end

  def self.roles_list_for_user(user, exclude_roles=nil)
    exclude_roles ||= []
    unless user.is_system_admins?
      exclude_roles << Role.where.not(id: Role.get_role_id(Role::SSL_USER)).map(&:id).uniq
    end
    exclude_roles.any? ? Role.where.not(id: exclude_roles.flatten) : Role.all
  end

  def self.get_user_accounts_roles(user)
    mapped_roles = Role.all.map{|r| [r.id, r.name]}.to_h
    user.ssl_accounts.inject({}) do |all, s|
      all[s.id] = user.assignments.where(ssl_account_id: s.id).pluck(:role_id).uniq
      all
    end
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

  def role_symbols(target_account=nil)
    Role.where(id: roles_for_account(target_account || ssl_account))
      .map{|role| role.name.underscore.to_sym}
  end

  def role_symbols_all_accounts
    roles.map{|role| role.name.underscore.to_sym}
  end

  def is_admin?
    role_symbols.include? Role::SYS_ADMIN.to_sym
  end

  def is_super_user?
    role_symbols.include? Role::SUPER_USER.to_sym
  end

  def is_account_admin?
    role_symbols.include? Role::ACCOUNT_ADMIN.to_sym
  end

  def is_standard?
    role_symbols & [Role::ACCOUNT_ADMIN.to_sym, Role::SSL_USER.to_sym]
  end

  def is_ssl_user?
    role_symbols.include? Role::SSL_USER.to_sym
  end

  def is_reseller?
    role_symbols.include? Role::RESELLER.to_sym
  end

  def is_vetter?
    role_symbols.include? Role::VETTER.to_sym
  end

  def is_affiliate?
    !!ssl_account.try(:affiliate)
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

    # Update user info fetching from social network
    case omniauth['provider']
    when 'facebook'
      # fetch extra user info from facebook
    when 'twitter'
      # fetch extra user info from twitter
    end
  end

  def make_admin
    unless roles.map(&:name).include?(Role::SYS_ADMIN)
      roles << Role.find_by(name: Role::SYS_ADMIN)
    end
  end

  def remove_admin
    sysadmin_roles = get_roles_by_name(Role::SYS_ADMIN)

    if sysadmin_roles.any?
      sysadmin_roles.each do |r|
        if r.ssl_account_id.nil?
          r.delete
        else
          update_account_role(r.ssl_account_id, Role::SYS_ADMIN, Role::ACCOUNT_ADMIN)
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
          acct_number:    SslAccount.find(ssl.ssl_account_id).acct_number,
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
        approve_account(params)
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
    ssl.update(approved: false, token_expires: nil, approval_token: nil) if ssl
  end

  def approve_all_accounts
    ssl_account_users.update_all(
      approved: true, token_expires: nil, approval_token: nil
    )
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
    SslAccountUser.where(user_id: id, approved: true, user_enabled: true).map(&:ssl_account)
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
        approval_token: (params[:clear] ? nil : generate_approval_token)
      )
    end
  end

  def set_status_for_account(status_type, target_ssl=nil)
    ssl          = target_ssl.nil? ? ssl_account : target_ssl
    acc_admin_id = Role.get_role_id(Role::ACCOUNT_ADMIN)
    params       = {user_enabled: (status_type == :enabled)}

    target_ssl = if roles_for_account(ssl).include?(acc_admin_id)
      # if account_admin, disable access to this ssl account for all associated users
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
  
  def approve_account(params)
    ssl = get_ssl_acct_user_for_approval(params)
    ssl.update(approved: true, token_expires: nil, approval_token: nil) if ssl
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
    params = {user_id: id, approved: true}
    ssl = SslAccountUser.where(params.merge(user_enabled: true))
    ssl = SslAccountUser.where(params) unless ssl.any?
    ssl_accounts.find ssl.first.ssl_account_id
  end

  def self.change_login(old, new)
    #requires SQL statement to change login
    User.where('login LIKE ?', old).update_all(login: new)
  end
end
