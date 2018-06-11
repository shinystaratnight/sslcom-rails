class Tag < ActiveRecord::Base
  belongs_to :ssl_account
  has_many :taggings
  has_many :orders, through: :taggings, source: :taggable, source_type: 'Order'
  has_many :certificate_orders, through: :taggings,
           source: :taggable, source_type: 'CertificateOrder'
  has_many :certificate_contents, through: :taggings,
           source: :taggable, source_type: 'CertificateContent'
  
  validates :name, allow_nil: false, allow_blank: false, uniqueness: {
    case_sensitive: true,
    scope: :ssl_account_id,
    message: 'Tag already exists for this team.'
  }
  
  def self.update_for_model(object, tags_list=[])
    @object = object
    if tags_list.blank? || tags_list.empty?
      clear_tags
    else
      get_object_team
      current_tags = get_tag_names
      @remove_tags = current_tags - tags_list
      @new_tags    = tags_list - current_tags
    
      remove_tags
      add_tags
    end
  end
  
  def self.get_all_tag_names(target_object)
    target_object.tags.pluck(:name)
  end

  def self.get_object_team_tags(target_object)
    get_object_team(target_object)
    get_team_tags.order(taggings_count: :desc)
  end

  private

  def self.get_object_team(target_object=nil)
    @object = target_object unless target_object.nil?
    @team = @object.is_a?(Order) ? @object.billable : @object.ssl_account
  end
  
  def self.remove_tags
    @object.taggings.where(
      tag_id: get_team_tags.where(name: @remove_tags).ids
    ).destroy_all
  end 

  
  def self.add_tags
    if @new_tags.any?
      found_team_tags = get_team_tags.where(name: @new_tags)
      @new_team_tags  = @new_tags - found_team_tags.pluck(:name)

      add_tags_to_team
      
      @object.tags << (
        found_team_tags + get_team_tags.where(name: @new_team_tags)
      ).flatten.uniq
    end
  end
  
  def self.add_tags_to_team
    @new_team_tags.each { |name| @team.tags << Tag.new(name: name) }
  end
  
  def self.get_tag_names
    @object.tags.pluck(:name)
  end
  
  def self.clear_tags
    @object.tags.destroy_all
  end
  
  def self.get_team_tags
    @team.tags
  end
end
