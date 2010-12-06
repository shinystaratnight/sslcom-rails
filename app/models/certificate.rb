class Certificate < ActiveRecord::Base
  has_many    :product_variant_groups, :as => :variantable
  has_many    :validation_rulings, :as=>:validation_rulable
  has_many    :validation_rules, :through => :validation_rulings
  acts_as_publishable :live, :draft, :discontinue_sell
  belongs_to  :reseller_tier
  serialize   :icons
  serialize   :description
  serialize   :display_order
  serialize   :title
  preference  :certificate_chain, :string
  
  NUM_DOMAINS_TIERS = 2
  UCC_INITIAL_DOMAINS_BLOCK = 3
  UCC_MAX_DOMAINS = 200

  def price=(amount)
    self.amount = amount.gsub(/\./,"").to_i
  end

  def items_by_duration
    product_variant_groups.duration.map(&:product_variant_items).flatten
  end

  def items_by_domains
    product_variant_groups.domains.map(&:product_variant_items).flatten if product.include?('ucc')
  end

  def items_by_server_licenses
    product_variant_groups.server_licenses.map(&:product_variant_items).flatten if
      (is_ucc? || is_wildcard?)
  end

  def first_domains_tiers
    if product.include?('ucc')
      first = []
      items_by_domains.each_with_index {|d, i| first << d if i%NUM_DOMAINS_TIERS==0}
      first
    end
  end

  def num_durations
    if is_ucc?
      items_by_domains.size / NUM_DOMAINS_TIERS
    else
      items_by_duration.size
    end
  end

  def first_duration
    product_variant_groups.first.product_variant_items.first
  end

  def is_ucc?
    product.include?('ucc')
  end

  def is_wildcard?
    product.include?('wildcard')
  end

  def is_ev?
    product.include?('ev')
  end

  def is_dv?
    product.include?('free')
  end

  def is_multi?
    is_ucc? || is_wildcard?
  end

  def find_tier(tier)
    Certificate.find_by_product(product_root+tier+'tr')
  end

  def is_single?
    !is_multi?
  end

  def allow_wildcard_ucc?
    allow_wildcard_ucc
  end

  def site_seal
    SiteSeal.new(SiteSeal.generate_options(product))
  end

  def tiered?
    !reseller_tier.blank?
  end

  def product_root
    product.gsub(/\dtr$/,"")
  end

  def untiered
    if reseller_tier.blank?
      self
    else
      Certificate.find_by_product product_root
    end
  end

  def self.root_products
    Certificate.find(:all).sort{|a,b|
    a.display_order['all'] <=> b.display_order['all']}.reject{|c|
      c.product=~/\dtr/}
  end

  def self.tiered_products(tier)
    Certificate.find(:all).sort{|a,b|
    a.display_order['all'] <=> b.display_order['all']}.find_all{|c|
        c.product=~Regexp.new(tier)}
  end

  def to_param
    product_root
  end

  def certificate_chain_names
    parse_certificate_chain.transpose[0]
  end

  def certificate_chain_types
    parse_certificate_chain.transpose[1]
  end

  def parse_certificate_chain
    preferred_certificate_chain.split(",").
      map(&:strip).map{|a|a.split(":")}
  end
end
