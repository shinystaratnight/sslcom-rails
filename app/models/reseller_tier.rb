class ResellerTier < ActiveRecord::Base
  acts_as_sellable :cents => :amount, :currency => false
  has_many  :certificates
  has_many  :resellers
  serialize :description

  DEFAULT_TIER = 2
  PUBLIC_TIERS = *(1..5)

  # these tiers are for sale to the general public, otherwise the tier is customized and private to select resellers
  scope :general, ->{where{id>>PUBLIC_TIERS}}

  def self.sitemap
    ResellerTier.general
  end

  # this method creates the tier, products and adds the reseller.
  # options[:label] - the name of the tier. If it already exists, then this method will modify this tier
  # options[:products] - **not done** list of certificate or products and pricing to create (ie  for certificate_id 100 at $33.50 - {100: "33.50"})
  # options[:reseller_ids] - array of resellers to include into this tier
  # options[:discount_rate] - discoutn rate on all items.
  # example - ResellerTier.generate_tier(label: "custom", description: {"name": "bob's tier"}, reseller_ids:[Reseller.last.id], discount_rate: 0.5)
  def self.generate_tier(options)
    tier = find_or_create_by(label: options[:label])
    tier.description = options[:description]
    tier.published_as = "live"
    tier.save!
    options[:reseller_ids].each do |id|
      tier.resellers << Reseller.find(id)
    end
    Certificate.base_products.each do |cert|
      tier.certificates << cert.duplicate(discount_rate: options[:discount_rate], reseller_tier_label: options[:label])
    end
  end

  def price=(amount)
    self.amount = amount.gsub(/\./,"").to_i
  end

  def is_free?
    amount <= 0
  end

  def product_variant_items
    certificates.all.map(&:product_variant_groups).flatten.map(&:product_variant_items).flatten
  end

  def to_param
    id.to_s
  end
end
