class User < ActiveRecord::Base
  include V2MigrationProgressAddon
#  using_access_control
  has_many  :assignments
  has_many  :visitor_tokens
  has_many  :surls
  has_many  :roles, :through => :assignments
  has_many  :permissions, :through => :roles
  has_many  :legacy_v2_user_mappings, :as=>:user_mappable
  has_many  :duplicate_v2_users
  has_many  :other_party_requests
  has_many  :client_applications
  has_many  :tokens, :class_name => "OauthToken", :order => "authorized_at desc", :include => [:client_application]
  has_and_belongs_to_many :user_groups
  belongs_to :ssl_account
  attr_accessor :changing_password, :admin_update
  attr_accessible :login, :email, :password, :password_confirmation,
    :openid_identifier, :status
  attr_readonly :login unless MIGRATING_FROM_LEGACY
  validates :email, email: true, uniqueness: true #TODO look at impact on checkout

  acts_as_authentic do |c|
    c.validate_email_field = false
    c.session_ids = [nil, :shadow],
    c.transition_from_crypto_providers = LegacySslMd5,
    c.validates_length_of_password_field_options =
      {:on => :update, :minimum => 4,
      :if => '(has_no_credentials? && !admin_update) || changing_password'}
    c.validates_length_of_password_confirmation_field_options =
      {:on => :update, :minimum => 4,
      :if => '(has_no_credentials? && !admin_update) || changing_password'}
  end

  before_create {|u|
    u.status='enabled'
  }

  default_scope where{status << ['disabled']}.order(:created_at.desc)

  def has_role?(role)
    roles.map{|r|r.name.downcase}.include?(role.to_s)
  end

  def active?
    active
  end

  def activate!
    self.active = true
    save
  end

  def is_disabled?
    status=="disabled"
  end

  def deliver_activation_instructions!
    reset_perishable_token!
    UserNotifier.activation_instructions(self).deliver
  end

  def deliver_activation_confirmation!
    reset_perishable_token!
    UserNotifier.activation_confirmation(self).deliver
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
    self.login = params[:user][:login]
    self.email = params[:user][:email]
    save_without_session_maintenance
  end

  # the second will take care of setting any data that you want to happen
  # at activation. at the very least this will be setting active to true
  # and setting a pass, openid, or both.
  def activate!(params)
    self.active = true
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

  def role_symbols
    (roles || []).map do |role|
      role.name.underscore.to_sym
    end
  end

  def is_admin?
    role_symbols.include? :sysadmin
  end

  def is_super_user?
    role_symbols.include? :super_user
  end

  def is_standard?
    role_symbols.include? :customer
  end

  def is_affiliate?
    !!ssl_account.affiliate
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

  private

  def self.make_admin(username)
    u=User.find_by_login(username)
    sysadmin=Role.find_by_name("sysadmin")
    u.roles << Role.find_by_name("sysadmin") unless u.roles.include?(sysadmin)
    u.roles.delete(Role.find_by_name("customer"))
  end

  def self.change_login(old, new)
    #requires SQL statement to change login
    User.where('login LIKE ?', old).update_all(login: new)
  end
end
