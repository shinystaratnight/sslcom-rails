# == Schema Information
#
# Table name: product_variant_groups
#
#  id                    :integer          not null, primary key
#  description           :text(65535)
#  display_order         :integer
#  published_as          :string(255)
#  serial                :string(255)
#  status                :string(255)
#  text_only_description :text(65535)
#  title                 :string(255)
#  variantable_type      :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  variantable_id        :integer
#
# Indexes
#
#  index_product_variant_groups_on_variantable_id  (variantable_id)
#

class ProductVariantGroup < ApplicationRecord
  has_many :product_variant_items, dependent: :destroy
  belongs_to  :variantable, :polymorphic => true, touch: true
  validates_uniqueness_of :display_order, :scope => [:variantable_id, :variantable_type]

  scope :duration, ->{where{(published_as == "live") & (title == "Duration")}}
  scope :domains, ->{where{(published_as == "live") & (title == "Domains")}}
  scope :server_licenses, ->{where{(published_as == 'live') & (title == "Server Licenses")}}
end
