class Folder < ActiveRecord::Base
  belongs_to :ssl_account  
  has_many   :certificate_orders
  
  acts_as_tree dependent: :destroy, order: :name

  validates :name,
            presence: {allow_blank: false},
            uniqueness: {scope: [:ssl_account_id, :parent_id],  case_sensitive: false},
            format: { with: /\A[\w ]+\z/,
                      message: 'Letters, Numbers, Spaces and Underscores Only'
                    }

  after_save     :there_can_only_be_one_default_folder
  before_destroy :can_destroy?
  after_destroy  :there_can_only_be_one_default_folder
  after_destroy  :release_certificate_orders

  attr_reader :total_certificate_orders
  
  def get_folder_path
    if ancestors.any?
      ancestors.last.self_and_descendants.map(&:name).join('/')
    else
      name
    end
  end

  def self.show_folders?(user=nil)
    user.is_system_admins? ? false : Settings.folders == "show"
  end

  def folder_contents
    contents = []
    @total_certificate_orders = 0
    if self.descendants.count > 0
      self.self_and_descendants.each do |child_folder|
        certificate_orders = child_folder.certificate_orders.count
        contents << child_folder.id if certificate_orders > 0
        @total_certificate_orders +=certificate_orders
      end
    else
      contents << self.id
      @total_certificate_orders +=self.certificate_orders.count
    end
    contents.join(',')
  end

  def can_destroy?
    !archived? && !expired? && !active? && !revoked?
  end

  def self.reset_to_system_folders(team,options={})
    if team
      co_list = CertificateOrder.unscoped{team.certificate_orders.joins(:signed_certificates)}
      folders = team.folders
      expired_folder = options[:expired_folder] || folders.find_by(expired: true)
      revoked_folder = options[:revoked_folder] || folders.find_by(revoked: true)
      active_folder = options[:active_folder] || folders.find_by(active: true)
      default_folder = options[:default_folder] || folders.find_by(default: true)

      if expired_folder
        co_list.expired.update_all(folder_id: expired_folder.id)
      end
      if revoked_folder
        co_list.revoked.update_all(folder_id: revoked_folder.id)
      end
      if active_folder
        co_list.where.not(id:
          (co_list.expired.ids + co_list.revoked.ids + co_list.unused_credits.ids).flatten.compact.uniq
        ).update_all(folder_id: active_folder.id)
      end
      if default_folder
        co_list.unused_credits.update_all(folder_id: default_folder.id)
      end
    end
  end

  protected

  # if this is going to be the default folder, all others should not
  def there_can_only_be_one_default_folder
    if default
      if self.destroyed?
        # If this was the default folder and just destroyed, make sure another folder becomes default
        if ssl_account.default_folder_id == id
          # Try to find some other folder that was marked default if possible. otherwise first avail
          another_top_level_folder = Folder.where(parent_id: nil, default: true).where.not(id: id).first ||
                                      Folder.where(parent_id: nil, default: false).where.not(id: id).first
          if another_top_level_folder
            another_top_level_folder.update_attribute(:default, true)
            ssl_account.update_attribute(:default_folder_id, another_top_level_folder.id)
          else
            ssl_account.update_attribute(:default_folder_id, nil)
          end
        end
      else
        # If this is the default folder and saved normally, make sure there are no other defaults
	      ssl_account.folders.where.not(id: id).update_all(default: false)
        ssl_account.update_attribute(:default_folder_id, id)
      end
    else
      # If this isn't a default folder, check to see if there are any others. If not, promote this one
      if Folder.where(default: true).count == 0
        unless self.destroyed?
          self.update_attribute(:default, true)
          ssl_account.update_attribute(:default_folder_id, id)
        end
      end
    end
  end

  def release_certificate_orders
    certificate_orders.update_all(folder_id: nil)
  end
end
