class Certificate < ActiveRecord::Base
  has_many    :product_variant_groups, :as => :variantable
  has_many    :product_variant_items, through: :product_variant_groups
  has_many    :validation_rulings, :as=>:validation_rulable
  has_many    :validation_rules, :through => :validation_rulings
  has_many    :discounts, as: :discountable
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

  FREE_CERTS_CART_LIMIT=5

  #mapping from old to v2 products (see CertificateOrder#preferred_v2_product_description)
  MAP_TO_TRIAL=[["Comodo Trial SSL Certificate", "SSL128SCGN SSL Certificate",
    "SSL128TRIAL30 Trial SSL Certificate",
    "RapidSSL Trial (FreeSSL) SSL Certificate"], "premiumssl", "free"]
  MAP_TO_OV=[["Comodo Elite SSL Certificate",
    "Comodo Premium SSL Certificate", "Comodo InstantSSL SSL Certificate",
    "SSL128SCG2.5 SSL Certificate", "Comodo Pro SSL Certificate",
    "ssl certificate", "RapidSSL SSL Certificate", "XRamp Enterprise SSL Certificate"],
    "basicssl", "basicssl"]
  MAP_TO_EV=[["thawte SGC SuperCert SSL Certificate",
    "Geotrust QuickSSL Premium SSL Certificate",
    "Verisign Secure Site SSL Certificate", "thawte SSL Web Server Cert",
    "XRamp Premium SSL Certificate", "SSL128SCG10 SSL Certificate",
    "SSL123 thawte Certificate", "Comodo Platinum SSL Certificate",
    "Verisign Secure Site Pro SSL Certificate",
    "Comodo Gold SSL Certificate"], "ev", "ev"]
  MAP_TO_WILDCARD=[["XRamp Premium Wildcard Certificate", "Comodo Premium Wildcard Certificate",
    "RapidSSL Wildcard Certificate", "Comodo Platinum Wildcard Certificate",
    "XRamp Enterprise Wildcard Certificate",
    "SSL128WCG10 Wildcard SSL Certificate"], "wildcard", "wildcard"]
  MAP_TO_UCC=[["SSL UC Certificate"], "ucc", "ucc"]

  SUBSCRIBER_AGREEMENTS = {
    free: {title: "Free SSL Subscriber Agreement",
          location: "public/agreements/free_ssl_subscriber_agreement.txt"},
    ev:   {title: "EV SSL Subscriber Agreement",
          location: "public/agreements/ssl_subscriber_agreement.txt"},
    high_assurance:  {title: "High Assurance SSL Subscriber Agreement",
          location: "public/agreements/ssl_subscriber_agreement.txt"},
    ucc:  {title: "UCC SSL Subscriber Agreement",
          location: "public/agreements/ssl_subscriber_agreement.txt"},
    evucc:   {title: "Enterprise EV SSL Subscriber Agreement",
          location: "public/agreements/ssl_subscriber_agreement.txt"},
    wildcard: {title: "Wildcard SSL Subscriber Agreement",
          location: "public/agreements/ssl_subscriber_agreement.txt"},
    basicssl: {title: "Basic SSL Subscriber Agreement",
          location: "public/agreements/ssl_subscriber_agreement.txt"},
    premiumssl: {title: "Premium SSL Subscriber Agreement",
          location: "public/agreements/ssl_subscriber_agreement.txt"}}

  WILDCARD_SWITCH_DATE = Date.strptime "02/09/2012", "%m/%d/%Y"
  #Comodo prods:
  #Essential Free SSL = 342
  #Essential SSL = 301
  #Essential SSL Wildcard = 343
  #Positive SSL MDC = 279
  #InstantSSL Wildcard = 35
  #43 was the old trial cert
  COMODO_PRODUCT_MAPPINGS =
      {"free"=> 342, "high_assurance"=>24, "wildcard"=>35, "ev"=>337,
       "ucc"=>361, "evucc"=>410}
  COMODO_PRODUCT_MAPPINGS_SSL_COM =
      {"free"=> 342, "high_assurance"=>301, "wildcard"=>343, "ev"=>337,
       "ucc"=>279, "evucc"=>410, "premiumssl"=>279, "basicssl"=>301}

  # ssl_ca_bundle.txt is the same as COMODOHigh-AssuranceSecureServerCA.crt
  # file_name => description (as displayed in emails)
  COMODO_BUNDLES = {"AddTrustExternalCARoot.crt"=>"Root CA Certificate",
                    "UTNAddTrustServerCA.crt"=>"Intermediate CA Certificate",
                    "EssentialSSLCA_2.crt"=>"Intermediate CA Certificate",
                    "UTNAddTrustSGCCA.crt"=>"Intermediate CA Certificate",
                    "ComodoUTNSGCCA.crt"=>"Intermediate CA Certificate",
                    "ssl_ca_bundle.txt"=>"High Assurance SSL.com CA Bundle",
                    "sslcom_addtrust_ca_bundle.txt"=>"SSL.com CA Bundle",
                    "sslcom_free_ca_bundle.txt"=>"Free SSL.com CA Bundle",
                    "sslcom_high_assurance_ca_bundle.txt"=>"High Assurance SSL.com CA Bundle",
                    "sslcom_ev_ca_bundle.txt"=>"EV SSL.com CA Bundle",
                    "SSLcomHighAssuranceCA.crt"=>"High Assurance SSL.com CA Bundle",
                    "free_ssl_ca_bundle.txt"=>"Free SSL.com CA Bundle",
                    "trial_ssl_ca_bundle.txt"=>"Trial SSL.com CA Bundle",
                    "COMODOAddTrustServerCA.crt"=>"Intermediate CA Certificate",
                    "SSLcomPremiumEVCA.crt"=>"Intermediate CA Certificate",
                    "SSLcomAddTrustSSLCA.crt"=>"Intermediate CA Certificate",
                    "SSLcomFreeSSLCA.crt"=>"Intermediate CA Certificate",
                    "COMODOExtendedValidationSecureServerCA.crt"=>"Intermediate CA Certificate",
                    "EntrustSecureServerCA.crt"=>"Root CA Certificate",
                    "USERTrustLegacySecureServerCA.crt"=>"Intermediate CA Certificate"}

  scope :public, where{(product != 'mssl') & (serial =~ "%sslcom%") & (product !~ 'high_assurance%')}
  scope :sitemap, where{(product != 'mssl') & (product !~ '%tr')}
  scope :for_sale, where{(serial =~ "%sslcom%")}

  def self.map_to_legacy(description, mapping=nil)
    [MAP_TO_TRIAL,MAP_TO_OV,MAP_TO_EV,MAP_TO_WILDCARD,MAP_TO_UCC].each do |m|
      type = mapping=='renew' ? 1 : 2
      return Certificate.find_by_product(m[type]) if m[0].include?(description)
    end
  end

  def price=(amount)
    self.amount = amount.gsub(/\./,"").to_i
  end

  def items_by_duration
    product_variant_groups.duration.map(&:product_variant_items).
        flatten.sort{|a,b|a.value.to_i <=> b.value.to_i}
  end

  def items_by_domains
    product_variant_groups.domains.map(&:product_variant_items).flatten if is_ucc?
  end

  def items_by_server_licenses
    product_variant_groups.server_licenses.map(&:product_variant_items).flatten if
      (is_ucc? || is_wildcard?)
  end

  def first_domains_tiers
    if is_ucc?
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

  def last_duration
    product_variant_groups.first.product_variant_items.last
  end

  def is_ucc?
    product.include?('ucc') || product.include?('premiumssl')
  end

  def is_wildcard?
    product.include?('wildcard')
  end

  def is_ev?
    product.include?('ev')
  end

  def is_premium_ssl?
    product_root=="premiumssl"
  end

  def is_dv?
    product.include?('free')
  end

  def is_free?
    product.include?('free')
  end

  def is_multi?
    is_ucc? || is_wildcard?
  end

  # use the essential ssl chain certs for these products
  # Essential Free SSL = 342
  # Essential SSL = 301
  # Essential SSL Wildcard = 343
  # Positive SSL MDC = 279
  def is_essential_ssl?
    [342,301,343,279].include? comodo_product_id
  end

  def find_tier(tier)
    Certificate.public.find_by_product(product_root+tier+'tr')
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

  def serial_root
    serial.gsub(/\dtr$/,"")
  end

  def untiered
    if reseller_tier.blank?
      self
    else
      Certificate.public.find_by_product product_root
    end
  end

  def self.root_products
    Certificate.public.sort{|a,b|
    a.display_order['all'] <=> b.display_order['all']}.reject{|c|
      c.product=~/\dtr/}
  end

  def self.tiered_products(tier)
    Certificate.public.sort{|a,b|
    a.display_order['all'] <=> b.display_order['all']}.find_all{|c|
        c.product=~Regexp.new(tier)}
  end

  def to_param
    product_root
  end

  def subscriber_agreement
    SUBSCRIBER_AGREEMENTS[product_root.to_sym]
  end

  def duration_in_days(duration)
    if is_ucc?
      items_by_domains.select{|n|n.display_order==duration.to_i}.last.value
    else
      items_by_duration[duration.to_i-1].value
    end
  end

  def duration_index(value)
    if is_ucc?
      items_by_domains.find{|d|d.value==value.to_s}.display_order
    else
      items_by_duration.map(&:value).index(value.to_s)+1
    end
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

  def comodo_product_id
    if self.serial=~/256sslcom/
      COMODO_PRODUCT_MAPPINGS_SSL_COM[product_root]
    else
      COMODO_PRODUCT_MAPPINGS[product_root]
    end
  end

  #deep level copying function, copies own attributes and then duplicates the sub groups and items
  def duplicate(new_serial, old_pvi_serial, new_pvi_serial)
    now=DateTime.now
    new_cert = self.dup
    new_cert.attributes = {created_at: now, updated_at: now,
                           serial: self.serial.gsub(/.+?(\dtr)?$/, new_serial+'\1')}
    new_cert.save
    self.product_variant_groups.each do |pvg|
      new_pvg = pvg.dup
      new_pvg.attributes = {created_at: now, updated_at: now}
      new_cert.product_variant_groups << new_pvg
      pvg.product_variant_items.each do |pvi|
        new_pvi=pvi.dup
        new_pvi.attributes = {created_at: now, updated_at: now, serial: pvi.serial.gsub(old_pvi_serial, new_pvi_serial)}
        new_pvg.product_variant_items << new_pvi
        unless pvi.sub_order_item.blank?
          new_pvi.sub_order_item=pvi.sub_order_item.dup
          new_pvi.sub_order_item.attributes = {created_at: now, updated_at: now}
          new_pvi.sub_order_item.save
        end
      end
    end
    new_cert
  end

  def duplicate_tiers(new_serial, old_pvi_serial, new_pvi_serial)
    sr = "#{self.serial_root}%"
    Certificate.where{serial =~ sr}.map {|c|c.duplicate(new_serial, old_pvi_serial, new_pvi_serial)}
  end

  # one-time call to create ssl.com product lines to supplant Comodo Essential SSL
  def self.create_sslcom_products
    %w(evucc ucc ev ov dv wc).each do |serial|
      s = self.serial+"%"
      Certificate.where{serial =~ s}.first.duplicate_tiers serial+"256sslcom"
    end
  end

  # one-time call to create ssl.com premium products
  def self.create_premium_ssl
    c=Certificate.public.find_by_product "ucc"
    certs = c.duplicate_tiers "premium256sslcom", "ucc256ssl", "premium256ssl"
    title = "Premium Multi-subdomain SSL"
    description={
        "certificate_type" => "Premium SSL",
                  "points" => "<div class='check'>quick domain validation</div>
                               <div class='check'>results in higher sales conversion</div>
                               <div class='check'>$10,000 USD insurance guaranty</div>
                               <div class='check'>works on MS Exchange or OWA</div>
                               <div class='check'>activates SSL Secure Site Seal</div>
                               <div class='check'>2048 bit public key encryption</div>
                               <em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>
                               <div class='check'>quick issuance</div>
                               <div class='check'>30 day unconditional refund</div>
                               <div class='check'>24 hour support</div>
                               <div class='check'>unlimited reissuances</div>",
        "validation_level" => "domain",
                 "summary" => "for securing small to medium sites",
                    "abbr" => "Premium SSL"
    }
    certs.each do |c|
      c.update_attributes title: title,
                          description: description,
                          product: c.product.gsub(/^ucc/, "premiumssl")
    end
    price_adjusts={sslcompremium256ssl1yrdm: [9900, 17820, 25245, 31680, 37125],
     sslcompremium256ssl1yrdm1tr: [9900, 17820, 25245, 31680, 37125],
     sslcompremium256ssl1yrdm2tr: [7920, 14256, 20196, 25344, 29700],
     sslcompremium256ssl1yrdm3tr: [7425, 13365, 18934, 23760, 27844],
     sslcompremium256ssl1yrdm4tr: [6831, 12296, 17419, 21859, 25616],
     sslcompremium256ssl1yrdm5tr: [5940, 10692, 15147, 19008, 22275]
    }
    price_adjusts.each do |k,v|
      serials=[]
      1.upto(5){|i|serials<<k.to_s.gsub(/1yr/, i.to_s+"yr")}
      serials.each_with_index {|s, i|ProductVariantItem.find_by_serial(s).update_attribute(:amount, (v[i]/3).ceil)}
    end
  end

  def self.create_basic_ssl
    c=Certificate.public.find_by_product "high_assurance"
    certs = c.duplicate_tiers "basic256sslcom", "ov256ssl", "basic256ssl"
    title = "Basic SSL"
    description={
        "certificate_type" => "Basic SSL",
                  "points" => "<div class='check'>quick domain validation</div>
                               <div class='check'>results in higher sales conversion</div>
                               <div class='check'>$10,000 USD insurance guaranty</div>
                               <div class='check'>activates SSL Secure Site Seal</div>
                               <div class='check'>2048 bit public key encryption</div>
                               <em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>
                               <div class='check'>quick issuance</div>
                               <div class='check'>30 day unconditional refund</div>
                               <div class='check'>24 hour support</div>
                               <div class='check'>unlimited reissuances</div>",
        "validation_level" => "domain",
                 "summary" => "for securing small sites",
                    "abbr" => "Basic SSL"
    }
    certs.each do |c|
      c.update_attributes title: title,
                          description: description,
                          product: c.product.gsub(/^high_assurance/, "basicssl"),
                          icons: c.icons.merge!("main"=> "silver_lock_lg.gif")
    end
    price_adjusts={sslcombasic256ssl1yr: [4900, 8820, 12495, 15680, 18375],
    sslcombasic256ssl1yr1tr: [4900, 8820, 12495, 15680, 18375],
    sslcombasic256ssl1yr2tr: [3920, 7056, 9996, 12544, 14700],
    sslcombasic256ssl1yr3tr: [3675, 6615, 9371, 11760, 13781],
    sslcombasic256ssl1yr4tr: [3381, 6086, 8622, 10819, 12679],
    sslcombasic256ssl1yr5tr: [2940, 5292, 7497, 9408, 11025]
    }
    price_adjusts.each do |k,v|
      serials=[]
      1.upto(5){|i|serials<<k.to_s.gsub(/1yr/, i.to_s+"yr")}
      serials.each_with_index {|s, i|ProductVariantItem.find_by_serial(s).update_attribute(:amount, v[i])}
    end
  end

  def self.transform_products_05282012
    create_premium_ssl
    create_basic_ssl
    Certificate.where{product =~ "ev%"}.each do |c|
      c.description.merge!(certificate_type: "Enterprise EV")
      c.title = "Enterprise EV SSL"
      c.save
    end
    Certificate.where{product =~ "evucc%"}.each do |c|
      c.description.merge!(certificate_type: "Enterprise EV UCC")
      c.title = "Enterprise EV Multi-domain UCC SSL"
      c.save
    end
  end
end