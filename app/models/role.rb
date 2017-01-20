class Role < ActiveRecord::Base
  has_many                  :assignments, dependent: :destroy
  has_many                  :users, :through => :assignments
  has_and_belongs_to_many   :permissions
  belongs_to                :ssl_account

  ACCOUNT_ADMIN = 'account_admin'
  BILLING       = 'billing'
  INSTALLER     = 'installer'
  OWNER         = 'owner'
  RESELLER      = 'reseller'
  SUPER_USER    = 'super_user'
  SYS_ADMIN     = 'sysadmin'
  VALIDATIONS   = 'validations'
  
  def self.get_role_id(role_name)
    Role.find_by(name: role_name).id
  end

  def self.get_role_ids(role_names)
    Role.where(name: role_names).ids.uniq.reject(&:blank?).compact
  end

  def self.admin_role_ids
    Role.get_role_ids([SYS_ADMIN, SUPER_USER, OWNER])
  end

  def self.get_account_admin_id
    Role.get_role_id(Role::ACCOUNT_ADMIN)
  end
    
  def self.get_owner_id
    Role.get_role_id(Role::OWNER)
  end
end
