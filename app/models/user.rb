class User < ActiveRecord::Base
  using_access_control
  has_many  :assignments
  has_many  :roles, :through => :assignments
  has_many  :legacy_v2_user_mappings, :as=>:user_mappable
  has_many  :duplicate_v2_users
  belongs_to :ssl_account
  attr_accessor :changing_password, :admin_update
  attr_accessible :login, :email, :password, :password_confirmation,
    :openid_identifier, :status
  attr_readonly :login
  acts_as_authentic do |c|
    c.session_ids = [nil, :shadow],
    c.transition_from_crypto_providers = Authlogic::CryptoProviders::LegacySslMd5,
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

  default_scope :order => 'users.created_at DESC'

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
    UserNotifier.deliver_activation_instructions(self)
  end

  def deliver_activation_confirmation!
    reset_perishable_token!
    UserNotifier.deliver_activation_confirmation(self)
  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    UserNotifier.deliver_password_reset_instructions(self)
  end

  def deliver_username_reminder!
    UserNotifier.deliver_username_reminder(self)
  end

  def deliver_password_changed!
    UserNotifier.deliver_password_changed(self)
  end

  def deliver_email_changed!(address=self.email)
    UserNotifier.deliver_email_changed(self, address)
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

  def role_symbols
    roles.map do |role|
      role.name.underscore.to_sym
    end
  end

  def is_admin?
    role_symbols.include? :sysadmin
  end

  def is_standard?
    role_symbols.include? :customer
  end

  def self.duplicate_logins(obj)
    if obj.is_a? User
    else #assume string
      
    end
  end

  #temporary function to assist in migration
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
