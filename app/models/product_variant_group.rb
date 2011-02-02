class ProductVariantGroup < ActiveRecord::Base
  has_many :product_variant_items
  belongs_to  :variantable, :polymorphic => true
  validates_uniqueness_of :display_order, :scope => [:variantable_id, :variantable_type]

  scope :duration, :conditions => {:published_as => "live", :title => "Duration"}
  scope :domains, :conditions => {:published_as => "live", :title => "Domains"}
  scope :server_licenses, :conditions => {:published_as => "live", :title => "Server Licenses"}
end
