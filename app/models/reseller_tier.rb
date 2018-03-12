class ResellerTier < ActiveRecord::Base
  acts_as_sellable :cents => :amount, :currency => false
  has_many  :certificates
  has_many  :resellers
  serialize :description

  DEFAULT_TIER = 2
  PUBLIC_TIERS = [7,8,*(1..5)]

  # these tiers are for sale to the general public, otherwise the tier is customized and private to select resellers
  scope :general, ->{where{id>>PUBLIC_TIERS}}

  def self.sitemap
    ResellerTier.general
  end

  # this method creates the tier, products and adds the reseller.
  # options[:label] - the name of the tier. If it already exists, then this method will modify this tier
  # options[:products] - **not done** list of certificate or products and pricing to create (ie  for certificate_id 100 at $33.50 - {100: "33.50"})
  # options[:reseller_ids] - array of resellers to include into this tier
  # options[:amount]- (optional) deposit buy-in
  # options[:roles]- (optional) role label
  # options[:discount_rate] - discount rate on all items.
  # example - ResellerTier.generate_tier(label: "custom", description: {"name": "bob's tier"}, reseller_ids:[Reseller.last.id], discount_rate: 0.5)
  # ResellerTier.generate_tier(label: "7", description: {"ideal_for"=> "enterprise organizations"}, discount_rate: 0.35, amount: 5000000, roles: "tier_7_reseller")
  # ResellerTier.generate_tier(label: "6", description: {"ideal_for"=> "enterprise organizations"}, discount_rate: 0.5, amount: 3500000, roles: "tier_6_reseller")  def self.generate_tier(options)
    tier = find_or_create_by(label: options[:label])
    tier.description = options[:description]
    tier.published_as = "live"
    tier.amount = options[:amount]
    tier.roles = options[:roles]
    tier.save!
    options[:reseller_ids].each do |id|
      tier.resellers << Reseller.find(id)
    end if options[:reseller_ids]
    Certificate.base_products.available.each do |cert|
      tier.certificates << cert.duplicate(discount_rate: options[:discount_rate], reseller_tier_label: options[:label],
                                          amount: options[:amount], roles: options[:roles])
    end
  end

  def price=(amount)
    self.amount = amount.gsub(/\./,"").to_i
  end

  def is_free?
    amount <= 0
  end

  def self.tier_suffix(label)
    "#{'-' unless (label =~/\A(\d)\z/ and $1.to_i < 6)}"+label + 'tr' #add '-' for non single digit tier due to flexible labeling
  end

  def product_variant_items
    certificates.all.map(&:product_variant_groups).flatten.map(&:product_variant_items).flatten
  end

  def to_param
    id.to_s
  end
end
