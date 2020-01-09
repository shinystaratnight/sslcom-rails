# frozen_string_literal: true

class Folder < ApplicationRecord
  extend Memoist

  belongs_to :ssl_account
  belongs_to :parent, foreign_key: 'parent_id', class_name: 'Folder'
  has_many   :certificate_orders

  acts_as_tree dependent: :destroy, order: :name

  validates :name,
            presence: { allow_blank: false },
            uniqueness: { scope: %i[ssl_account_id parent_id], case_sensitive: false },
            format: { with: /\A[\w ]+\z/,
                      message: 'Letters, Numbers, Spaces and Underscores Only' }

  after_save     :there_can_only_be_one_default_folder
  before_destroy :can_destroy?
  after_destroy  :there_can_only_be_one_default_folder
  after_destroy  :release_certificate_orders

  attr_reader :total_certificate_orders

  def cached_certificate_orders
    CertificateOrder.where(id: (Rails.cache.fetch("#{cache_key}/cached_certificate_orders") do
      certificate_orders.pluck(:id)
    end)).includes(certificate_contents: %i[signed_certificates registrant]).order(created_at: :desc)
  end
  memoize :cached_certificate_orders

  def get_folder_path
    if ancestors.any?
      ancestors.last.self_and_descendants.map(&:name).join('/')
    else
      name
    end
  end

  def self.show_folders?(user = nil)
    user.is_system_admins? ? false : Settings.folders == 'show'
  end

  def folder_contents
    contents = []
    @total_certificate_orders = 0
    if descendants&.count&.positive?
      self_and_descendants.includes(:certificate_orders).find_each do |child_folder|
        certificate_orders = child_folder.certificate_orders.count
        contents << child_folder.id if certificate_orders.positive?
        @total_certificate_orders += certificate_orders
      end
    else
      contents << id
      @total_certificate_orders += self.certificate_orders.count
    end
    contents.join(',')
  end
  memoize :folder_contents

  def can_destroy?
    !archived? && !expired? && !active? && !revoked?
  end

  def self.reset_to_system_folders(team, options = {})
    if team
      co_list = team.certificate_orders.joins{ signed_certificates.outer }
      folders = team.folders
      expired_folder = options[:expired_folder] || folders.find_by(expired: true)
      revoked_folder = options[:revoked_folder] || folders.find_by(revoked: true)
      active_folder = options[:active_folder] || folders.find_by(active: true)
      default_folder = options[:default_folder] || folders.find_by(default: true)

      co_list.expired.where{ (folder_id != expired_folder.id) | folder_id.nil? }.update_all(folder_id: expired_folder.id) if expired_folder
      co_list.revoked.where{ (folder_id != revoked_folder.id) | folder_id.nil? }.update_all(folder_id: revoked_folder.id) if revoked_folder
      co_list.unused_credits.where{ (folder_id != default_folder.id) | folder_id.nil? }.update_all(folder_id: default_folder.id) if default_folder
      if active_folder
        co_list.where do
          id <<
            (co_list.expired.ids + co_list.revoked.ids + co_list.unused_credits.ids).flatten.compact.uniq
        end.update_all(folder_id: active_folder.id)
      end
    end
  end

  protected

  # if this is going to be the default folder, all others should not
  def there_can_only_be_one_default_folder
    if destroyed?
      # create a new default folder if default is destroyed
      if default
        new_default = ssl_account.folders.create(default: true, name: 'default')
        ssl_account.update_column(:default_folder_id, new_default.id) if new_default.persisted?
      end
    else
      # If this is the default folder and saved normally, make sure there are no other defaults
      if default && can_destroy?
        ssl_account&.folders&.where&.not(id: id)&.where(default: true)&.update_all(default: false)
        ssl_account&.update_column(:default_folder_id, id)
      end
    end
  end

  def release_certificate_orders
    certificate_orders.update_all(folder_id: nil)
  end
end
