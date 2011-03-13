class ResellerTier < ActiveRecord::Base
  acts_as_sellable :cents => :amount, :currency => false
  has_many  :certificates
  has_many  :resellers
  serialize :description

  DEFAULT_TIER = 2

  def self.sitemap
    ResellerTier.all
  end

  def price=(amount)
    self.amount = amount.gsub(/\./,"").to_i
  end

  def product_variant_items
    certificates.all.map(&:product_variant_groups).flatten.map(&:product_variant_items).flatten
  end

  def to_param
    id.to_s
  end
end
