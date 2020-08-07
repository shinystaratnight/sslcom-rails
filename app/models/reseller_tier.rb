class ResellerTier < ApplicationRecord
  include PriceView
  acts_as_sellable cents: :amount, currency: false
  has_many  :certificates, dependent: :destroy
  has_many  :product_variant_groups, through: :certificates
  has_many  :product_variant_items, through: :certificates
  has_many  :resellers
  serialize :description

  DEFAULT_TIER = 2
  PUBLIC_TIERS = [7, 8, *(1..5)].freeze
  TIER_KEY = :r_tier_102019

  # these tiers are for sale to the general public, otherwise the tier is customized and private to select resellers
  scope :general, ->{ where{ id >> PUBLIC_TIERS } }

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
  # ResellerTier.generate_tier(label: "6", description: {"ideal_for"=> "enterprise organizations"}, discount_rate: 0.5, amount: 3500000, roles: "tier_6_reseller")
  # ResellerTier.generate_tier(label: "ansonnet", description: {:name=>"ansonnet tier"}, discount_rate: 0.315)
  # ResellerTier.generate_tier(label: "dtntcomodoca", description: {:name=>"dtnt comodoca tier"}, discount_rate: 0.167)
  def self.generate_tier(options)
    where(label: options[:label]).first_or_create do |record|
      record.description = options[:description]
      record.published_as = 'live'
      record.amount = options[:amount]
      record.roles = options[:roles]
      record.resellers << options[:reseller_ids].map { |id| Reseller.find(id) } if options[:reseller_ids]
      record.certificates << Certificate.base_products.available.map do |cert|
        cert.duplicate(discount_rate: options[:discount_rate], reseller_tier_label: options[:label], amount: options[:amount], roles: options[:roles])
      end
    end
  end

  def price=(amount)
    self.amount = amount.gsub(/\./, '').to_i
  end

  def is_free?
    amount <= 0
  end

  def self.tier_suffix(label)
    "#{'-' unless label =~ /\A(\d)\z/ && (Regexp.last_match(1).to_i < 6)}#{label}tr" # add '-' for non single digit tier due to flexible labeling
  end

  def to_param
    id.to_s
  end

  # sample commands to create a new tier and update pricing
  #
  # label="dtntcomodoca"
  # rt=ResellerTier.generate_tier(label: label, description: {:name=>"#{label} tier"}, discount_rate: 0.167)
  # rt=ResellerTier.find_by_label(label)
  # rt.prices_matrix
  # options= {11108=>["Enterprise EV Multi-domain UCC SSL", "Domains", "1 Year Domain For 3 Domains (ea domain)", 5000],
  #           11109=>["Enterprise EV Multi-domain UCC SSL", "Domains", "1 Year Domain For Domains 4-200 (ea domain)", 5000],
  #           11110=>["Enterprise EV Multi-domain UCC SSL", "Domains", "2 Year Domain For 3 Domains (ea domain)", 10000],
  #           11111=>["Enterprise EV Multi-domain UCC SSL", "Domains", "2 Year Domain For Domains 4-200 (ea domain)", 10000],
  #           11112=>["Enterprise EV Multi-domain UCC SSL", "Server Licenses", "1 Year Additional Server License", 167],
  #           11113=>["Enterprise EV Multi-domain UCC SSL", "Server Licenses", "2 Years Additional Server License", 301],
  #           11114=>["Multi-domain UCC SSL", "Domains", "1 Year Domain For 3 Domains (ea domain)", 750],
  #           11115=>["Multi-domain UCC SSL", "Domains", "1 Year Domain For Domains 4-200 (ea domain)", 750],
  #           11116=>["Multi-domain UCC SSL", "Domains", "2 Year Domain For 3 Domains (ea domain)", 1350],
  #           11117=>["Multi-domain UCC SSL", "Domains", "2 Year Domain For Domains 4-200 (ea domain)", 1350],
  #           11118=>["Multi-domain UCC SSL", "Domains", "3 Year Domain For 3 Domains (ea domain)", 1950],
  #           11119=>["Multi-domain UCC SSL", "Domains", "3 Year Domain For Domains 4-200 (ea domain)", 1950],
  #           11120=>["Multi-domain UCC SSL", "Domains", "4 Year Domain For 3 Domains (ea domain)", 2550],
  #           11121=>["Multi-domain UCC SSL", "Domains", "4 Year Domain For Domains 4-200 (ea domain)", 2550],
  #           11122=>["Multi-domain UCC SSL", "Domains", "5 Year Domain For 3 Domains (ea domain)", 3150],
  #           11123=>["Multi-domain UCC SSL", "Domains", "5 Year Domain For Domains 4-200 (ea domain)", 3150],
  #           11124=>["Multi-domain UCC SSL", "Domains", "each 1 Year Wildcard Domain", 5000],
  #           11125=>["Multi-domain UCC SSL", "Domains", "each 2 Year Wildcard Domain", 10000],
  #           11126=>["Multi-domain UCC SSL", "Domains", "each 3 Year Wildcard Domain", 15000],
  #           11127=>["Multi-domain UCC SSL", "Domains", "each 4 Year Wildcard Domain", 20000],
  #           11128=>["Multi-domain UCC SSL", "Domains", "each 5 Year Wildcard Domain", 25000],
  #           11129=>["Multi-domain UCC SSL", "Server Licenses", "1 Year Additional Server License", 167],
  #           11130=>["Multi-domain UCC SSL", "Server Licenses", "2 Years Additional Server License", 301],
  #           11131=>["Multi-domain UCC SSL", "Server Licenses", "3 Years Additional Server License", 426],
  #           11132=>["Multi-domain UCC SSL", "Server Licenses", "4 Years Additional Server License", 535],
  #           11133=>["Multi-domain UCC SSL", "Server Licenses", "5 Years Additional Server License", 627],
  #           11134=>["Enterprise EV SSL", "Duration", "1 Year", 10000],
  #           11135=>["Enterprise EV SSL", "Duration", "2 Years", 18000],
  #           11136=>["High Assurance SSL", "Duration", "1 Year", 1000],
  #           11137=>["High Assurance SSL", "Duration", "2 Years", 1800],
  #           11138=>["High Assurance SSL", "Duration", "3 Years", 2600],
  #           11139=>["High Assurance SSL", "Duration", "4 Years", 3400],
  #           11140=>["High Assurance SSL", "Duration", "5 Years", 4200],
  #           11141=>["Free SSL", "Duration", "90 Days", 0],
  #           11142=>["Multi-subdomain Wildcard SSL", "Duration", "1 Year", 5000],
  #           11143=>["Multi-subdomain Wildcard SSL", "Duration", "2 Years", 10000],
  #           11144=>["Multi-subdomain Wildcard SSL", "Duration", "3 Years", 15000],
  #           11145=>["Multi-subdomain Wildcard SSL", "Duration", "4 Years", 20000],
  #           11146=>["Multi-subdomain Wildcard SSL", "Duration", "5 Years", 25000],
  #           11147=>["Multi-subdomain Wildcard SSL", "Server Licenses", "1 Year Additional Server License", 167],
  #           11148=>["Multi-subdomain Wildcard SSL", "Server Licenses", "2 Years Additional Server License", 301],
  #           11149=>["Multi-subdomain Wildcard SSL", "Server Licenses", "3 Years Additional Server License", 426],
  #           11150=>["Multi-subdomain Wildcard SSL", "Server Licenses", "4 Years Additional Server License", 535],
  #           11151=>["Multi-subdomain Wildcard SSL", "Server Licenses", "5 Years Additional Server License", 627],
  #           11152=>["Premium Multi-subdomain SSL", "Domains", "1 Year Domain For 3 Domains (ea domain)", 552],
  #           11153=>["Premium Multi-subdomain SSL", "Domains", "1 Year Domain For Domains 4-200 (ea domain)", 819],
  #           11154=>["Premium Multi-subdomain SSL", "Domains", "2 Year Domain For 3 Domains (ea domain)", 992],
  #           11155=>["Premium Multi-subdomain SSL", "Domains", "2 Year Domain For Domains 4-200 (ea domain)", 1473],
  #           11156=>["Premium Multi-subdomain SSL", "Domains", "3 Year Domain For 3 Domains (ea domain)", 1406],
  #           11157=>["Premium Multi-subdomain SSL", "Domains", "3 Year Domain For Domains 4-200 (ea domain)", 2087],
  #           11158=>["Premium Multi-subdomain SSL", "Domains", "4 Year Domain For 3 Domains (ea domain)", 1764],
  #           11159=>["Premium Multi-subdomain SSL", "Domains", "4 Year Domain For Domains 4-200 (ea domain)", 2717],
  #           11160=>["Premium Multi-subdomain SSL", "Domains", "5 Year Domain For 3 Domains (ea domain)", 2067],
  #           11161=>["Premium Multi-subdomain SSL", "Domains", "5 Year Domain For Domains 4-200 (ea domain)", 3274],
  #           11162=>["Premium Multi-subdomain SSL", "Server Licenses", "1 Year Additional Server License", 167],
  #           11163=>["Premium Multi-subdomain SSL", "Server Licenses", "2 Years Additional Server License", 301],
  #           11164=>["Premium Multi-subdomain SSL", "Server Licenses", "3 Years Additional Server License", 426],
  #           11165=>["Premium Multi-subdomain SSL", "Server Licenses", "4 Years Additional Server License", 535],
  #           11166=>["Premium Multi-subdomain SSL", "Server Licenses", "5 Years Additional Server License", 627],
  #           11167=>["Basic SSL", "Duration", "1 Year", 750],
  #           11168=>["Basic SSL", "Duration", "2 Years", 1350],
  #           11169=>["Basic SSL", "Duration", "3 Years", 1950],
  #           11170=>["Basic SSL", "Duration", "4 Years", 2550],
  #           11171=>["Basic SSL", "Duration", "5 Years", 3150],
  #           11172=>["Code Signing", "Duration", "1 Year", 2155],
  #           11173=>["Code Signing", "Duration", "2 Years", 3878],
  #           11174=>["Code Signing", "Duration", "3 Years", 5494],
  #           11175=>["Code Signing", "Duration", "4 Years", 6894],
  #           11176=>["Code Signing", "Duration", "5 Years", 8079],
  #           11177=>["Code Signing", "Duration", "6 Years", 9049],
  #           11178=>["Code Signing", "Duration", "7 Years", 9803],
  #           11179=>["Code Signing", "Duration", "8 Years", 10341],
  #           11180=>["Code Signing", "Duration", "9 Years", 10664],
  #           11181=>["Code Signing", "Duration", "10 Years", 10772],
  #           11182=>["EV Code Signing", "Duration", "1 Year", 13000],
  #           11183=>["EV Code Signing", "Duration", "2 Years", 24000],
  #           11184=>["EV Code Signing", "Duration", "3 Years", 31000],
  #           11185=>["Personal Basic", "Duration", "1 Year", 750],
  #           11186=>["Personal Basic", "Duration", "2 Years", 1350],
  #           11187=>["Personal Basic", "Duration", "3 Years", 1950],
  #           11188=>["Personal Business", "Duration", "1 Year", 1503],
  #           11189=>["Personal Business", "Duration", "2 Years", 2005],
  #           11190=>["Personal Business", "Duration", "3 Years", 2505],
  #           11191=>["Personal Pro", "Duration", "1 Year", 1169],
  #           11192=>["Personal Pro", "Duration", "2 Years", 1336],
  #           11193=>["Personal Pro", "Duration", "3 Years", 1503],
  #           11194=>["Personal Enterprise", "Duration", "1 Year", 4159],
  #           11195=>["Personal Enterprise", "Duration", "2 Years", 8334],
  #           11196=>["Personal Enterprise", "Duration", "3 Years", 10004],
  #           11197=>["Document Signing", "Duration", "1 Years", 5829],
  #           11198=>["Document Signing", "Duration", "2 Years", 10839],
  #           11199=>["Document Signing", "Duration", "3 Years", 14179],
  #           11200=>["NAESB Basic", "Duration", "1 Years", 1253],
  #           11201=>["NAESB Basic", "Duration", "2 Years", 2505]}
  # rt.update_prices(options)
  # sa = SslAccount.find_by_acct_number "a0a-1dpi0uq"
  # sa.adjust_reseller_tier label
  # bundle exec rake cas:seed_ejbca_profiles LIVE=all EJBCA_ENV=production RAILS_ENV=production # create mappings
end
