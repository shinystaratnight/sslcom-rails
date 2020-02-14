# frozen_string_literal: true

# == Schema Information
#
# Table name: product_variant_groups
#
#  id                    :integer          not null, primary key
#  variantable_id        :integer
#  variantable_type      :string(255)
#  title                 :string(255)
#  status                :string(255)
#  description           :text(65535)
#  text_only_description :text(65535)
#  display_order         :integer
#  serial                :string(255)
#  published_as          :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#

class ProductVariantGroup < ApplicationRecord
  has_many :product_variant_items, dependent: :destroy
  belongs_to :variantable, polymorphic: true, touch: true
  validates_uniqueness_of :display_order, scope: %i[variantable_id variantable_type]

  scope :duration, ->{ where{ (published_as == 'live') & (title == 'Duration') } }
  scope :domains, ->{ where{ (published_as == 'live') & (title == 'Domains') } }
  scope :server_licenses, ->{ where{ (published_as == 'live') & (title == 'Server Licenses') } }
end
