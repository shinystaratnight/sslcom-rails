# frozen_string_literal: true

# == Schema Information
#
# Table name: product_variant_items
#
#  id                       :integer          not null, primary key
#  amount                   :integer
#  description              :text(65535)
#  display_order            :integer
#  item_type                :string(255)
#  published_as             :string(255)
#  serial                   :string(255)
#  status                   :string(255)
#  text_only_description    :text(65535)
#  title                    :string(255)
#  value                    :string(255)
#  created_at               :datetime
#  updated_at               :datetime
#  product_variant_group_id :integer
#
# Indexes
#
#  index_product_variant_items_on_product_variant_group_id  (product_variant_group_id)
#

class ProductVariantItem < ApplicationRecord
  extend Memoist
  acts_as_sellable cents: :amount, currency: false
  belongs_to :product_variant_group, foreign_key: 'product_variant_group_id', inverse_of: :product_variant_items
  has_one :sub_order_item, dependent: :nullify
  acts_as_publishable :live, :draft, :discontinue_sell

  validates :product_variant_group_id, presence: true

  def certificate
    @pvi_certificate ||= product_variant_group.variantable if product_variant_group&.variantable&.is_a?(Certificate)
  end
  memoize :certificate

  def cached_certificate_id
    Rails.cache.fetch("#{cache_key}/cached_certificate_id") do
      certificate&.id
    end
  end

  def is_domain?
    item_type == 'ucc_domain'
  end

  def is_duration?
    item_type == 'duration'
  end

  def is_server_license?
    item_type == 'server_license'
  end

  def reseller_tier_of?(compare)
    compare.serial == base_serial if serial.match?(/tr\z/)
  end

  def reseller_tier_label
    serial.slice(/.+(?=(\d)tr)/) || serial.slice(/.+(?=(\-\w+?)tr)/)
    $1
  end

  private

  # A one time method to add wildcard domains as a separate charge item
  def self.add_wildcards_to_ucc
    tier_discounts = [1, 0.80, 0.75, 0.7, 0.6]
    prices = {ucc: 12900, evucc: 19900}
    out=[]
    Certificate.where{product =~ '%ucc%'}.flatten.map(&:product_variant_groups).
        flatten.find_all{|d|d.title=="Domains"}.
        flatten.map(&:product_variant_items).
        flatten.find_all{|d|d.title =~ /4-200/}.each do |pvi|
      #replace 'adm' with 'wcdm' in serial
      serial = pvi.serial.gsub "adm", "wcdm"
      pvi.serial =~ /(\d)tr\z/
      tier=$1
      type = pvi.serial =~ /ev/ ? :evucc : :ucc
      pvi.title =~ /\A(\d)/
      duration = $1
      amount = prices[type] * duration.to_i * (tier ? tier_discounts[tier.to_i-1] : 1)
      if type == :ucc #there is no evucc wildcard but kept the logic anyway
        ProductVariantItem.create amount: amount.round(2).to_i, serial: serial, title: "each #{duration} Year Wildcard Domain", description: "each #{duration} Year Wildcard Domain".downcase,
              text_only_description: "each #{duration} Year Wildcard Domain".downcase, display_order: duration,
              product_variant_group_id: pvi.product_variant_group_id, status: pvi.status, item_type: pvi.item_type,
              value: pvi.value, published_as: pvi.published_as
      end
    end
    out
  end

  # remove reseller_tier
  def base_serial
    serial.slice(/.+(?=\-.+?tr)/) || serial.slice(/.+(?=\dtr)/)
  end
end
