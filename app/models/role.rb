# == Schema Information
#
# Table name: roles
#
#  id             :integer          not null, primary key
#  description    :text(65535)
#  name           :string(255)
#  status         :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  ssl_account_id :integer
#
# Indexes
#
#  index_roles_on_ssl_account_id  (ssl_account_id)
#

class Role < ApplicationRecord
  has_many                  :assignments, dependent: :destroy
  has_many                  :users, through: :assignments
  has_and_belongs_to_many   :permissions
  belongs_to                :ssl_account

  ACCOUNT_ADMIN = 'account_admin'
  BILLING       = 'billing'
  INSTALLER     = 'installer'
  OWNER         = 'owner'
  RESELLER      = 'reseller'
  SUPER_USER    = 'super_user'
  SYS_ADMIN     = 'sysadmin'
  USERS_MANAGER = 'users_manager'
  VALIDATIONS   = 'validations'
  RA_ADMIN      = 'ra_admin'
  INDIVIDUAL_CERTIFICATE = 'individual_certificate'

  ALL = [ACCOUNT_ADMIN, BILLING, INSTALLER, OWNER, RESELLER, SUPER_USER, SYS_ADMIN, USERS_MANAGER, VALIDATIONS, RA_ADMIN, INDIVIDUAL_CERTIFICATE].freeze

  scope :for_owners, -> { order(:id).where{ name >> [ACCOUNT_ADMIN, BILLING, INSTALLER, VALIDATIONS, USERS_MANAGER, INDIVIDUAL_CERTIFICATE] } }
  scope :for_admins, -> { order(:id).where{ name >> [SYS_ADMIN, SUPER_USER, OWNER, RA_ADMIN] } }

  def self.get_role_id(role_name)
    Rails.cache.fetch(['get_role_id', role_name]) { Role.find_by(name: role_name).id }
  end

  def self.get_role_ids(role_names)
    Rails.cache.fetch(['get_role_ids', role_names.join('_')]) do
      Role.where(name: role_names).ids.uniq.reject(&:blank?).compact
    end
  end

  def self.admin_role_ids
    Role.get_role_ids([SYS_ADMIN, SUPER_USER, OWNER, RA_ADMIN])
  end

  def self.get_account_admin_id
    Role.get_role_id(Role::ACCOUNT_ADMIN)
  end

  def self.get_billing_id
    Role.get_role_id(Role::BILLING)
  end

  def self.get_owner_id
    Role.get_role_id(Role::OWNER)
  end

  def self.get_reseller_id
    Role.get_role_id(Role::RESELLER)
  end

  def self.get_individual_certificate_id
    Role.get_role_id(Role::INDIVIDUAL_CERTIFICATE)
  end

  def self.get_select_ids_for_owner
    Role.get_role_ids([
                        ACCOUNT_ADMIN,
                        BILLING,
                        INSTALLER,
                        VALIDATIONS,
                        USERS_MANAGER,
                        INDIVIDUAL_CERTIFICATE
                      ])
  end

  def self.can_auto_add_users
    Role.get_role_ids([
                        ACCOUNT_ADMIN,
                        OWNER,
                        RESELLER
                      ])
  end

  def self.can_manage_users
    Role.get_role_ids([
                        ACCOUNT_ADMIN,
                        OWNER,
                        RESELLER,
                        SUPER_USER,
                        SYS_ADMIN,
                        USERS_MANAGER
                      ])
  end

  def self.can_manage_billing
    Role.get_role_ids([
                        ACCOUNT_ADMIN,
                        BILLING,
                        OWNER,
                        RESELLER,
                        SUPER_USER,
                        SYS_ADMIN
                      ])
  end

  def self.can_manage_payable_invoice
    Role.get_role_ids([
                        ACCOUNT_ADMIN,
                        BILLING,
                        OWNER,
                        RESELLER
                      ])
  end

  #
  # Roles that cannot be managed by users_manager role
  #
  def self.cannot_be_managed
    Role.get_role_ids([
                        ACCOUNT_ADMIN,
                        OWNER,
                        RESELLER,
                        SUPER_USER,
                        SYS_ADMIN,
                        USERS_MANAGER,
                        RA_ADMIN
                      ])
  end

  def self.cannot_be_invited
    Role.get_role_ids([
                        OWNER,
                        RESELLER,
                        SUPER_USER,
                        SYS_ADMIN,
                        RA_ADMIN
                      ])
  end
end
