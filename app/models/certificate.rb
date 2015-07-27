class Certificate < ActiveRecord::Base
  has_many    :product_variant_groups, :as => :variantable
  has_many    :product_variant_items, through: :product_variant_groups
  has_many    :validation_rulings, :as=>:validation_rulable
  has_many    :validation_rules, :through => :validation_rulings
  acts_as_publishable :live, :draft, :discontinue_sell
  belongs_to  :reseller_tier
  serialize   :icons
  serialize   :description
  serialize   :display_order
  serialize   :title
  preference  :certificate_chain, :string

  NUM_DOMAINS_TIERS = 3
  UCC_INITIAL_DOMAINS_BLOCK = 3
  UCC_MAX_DOMAINS = 200

  FREE_CERTS_CART_LIMIT=5

  #mapping from old to v2 products (see CertificateOrder#preferred_v2_product_description)
  MAP_TO_TRIAL=[["Comodo Trial SSL Certificate", "SSL128SCGN SSL Certificate",
    "SSL128TRIAL30 Trial SSL Certificate",
    "RapidSSL Trial (FreeSSL) SSL Certificate"], "high_assurance", "free"]
  MAP_TO_OV=[["Comodo Elite SSL Certificate",
    "Comodo Premium SSL Certificate", "Comodo InstantSSL SSL Certificate",
    "SSL128SCG2.5 SSL Certificate", "Comodo Pro SSL Certificate",
    "ssl certificate", "RapidSSL SSL Certificate", "XRamp Enterprise SSL Certificate"],
    "high_assurance", "high_assurance"]
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
      {"free"=> 342, "high_assurance"=>301, "wildcard"=>343, "ev"=>301,
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
                    "ssl_ca_bundle_amazon.txt"=>"High Assurance SSL.com CA Bundle",
                    "sslcom_addtrust_ca_bundle_amazon.txt"=>"SSL.com CA Bundle",
                    "sslcom_free_ca_bundle_amazon.txt"=>"Free SSL.com CA Bundle",
                    "sslcom_high_assurance_ca_bundle_amazon.txt"=>"High Assurance SSL.com CA Bundle",
                    "sslcom_ev_ca_bundle.txt_amazon"=>"EV SSL.com CA Bundle",
                    "free_ssl_ca_bundle.txt_amazon"=>"Free SSL.com CA Bundle",
                    "trial_ssl_ca_bundle.txt_amazon"=>"Trial SSL.com CA Bundle",
                    "COMODOAddTrustServerCA.crt"=>"Intermediate CA Certificate",
                    "SSLcomPremiumEVCA.crt"=>"Intermediate CA Certificate",
                    "SSLcomAddTrustSSLCA.crt"=>"Intermediate CA Certificate",
                    "SSLcomFreeSSLCA.crt"=>"Intermediate CA Certificate",
                    "COMODOExtendedValidationSecureServerCA.crt"=>"Intermediate CA Certificate",
                    "EntrustSecureServerCA.crt"=>"Root CA Certificate",
                    "USERTrustLegacySecureServerCA.crt"=>"Intermediate CA Certificate"}

  # :dir - the directory under the bundles
  # :labels - the file names of the component ca chain certs
  # :contents - the bundle name and component files from :labels
  # after configuring a ca file set, run Certificate.generate_ca_certificates on the set to create the bundles

  BUNDLES = {comodo: {SHA1_2012: {
                        "AddTrustExternalCARoot.crt"=>"Root CA Certificate",
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
                        "ssl_ca_bundle_amazon.txt"=>"High Assurance SSL.com CA Bundle",
                        "sslcom_addtrust_ca_bundle_amazon.txt"=>"SSL.com CA Bundle",
                        "sslcom_free_ca_bundle_amazon.txt"=>"Free SSL.com CA Bundle",
                        "sslcom_high_assurance_ca_bundle_amazon.txt"=>"High Assurance SSL.com CA Bundle",
                        "sslcom_ev_ca_bundle.txt_amazon"=>"EV SSL.com CA Bundle",
                        "free_ssl_ca_bundle.txt_amazon"=>"Free SSL.com CA Bundle",
                        "trial_ssl_ca_bundle.txt_amazon"=>"Trial SSL.com CA Bundle",
                        "COMODOAddTrustServerCA.crt"=>"Intermediate CA Certificate",
                        "SSLcomPremiumEVCA.crt"=>"Intermediate CA Certificate",
                        "SSLcomAddTrustSSLCA.crt"=>"Intermediate CA Certificate",
                        "SSLcomFreeSSLCA.crt"=>"Intermediate CA Certificate",
                        "COMODOExtendedValidationSecureServerCA.crt"=>"Intermediate CA Certificate",
                        "EntrustSecureServerCA.crt"=>"Root CA Certificate",
                        "USERTrustLegacySecureServerCA.crt"=>"Intermediate CA Certificate"},
                      sha1_sslcom_2014: {
                        "AddTrustExternalCARoot.crt"=>"Root CA Certificate",
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
                        "ssl_ca_bundle_amazon.txt"=>"High Assurance SSL.com CA Bundle",
                        "sslcom_addtrust_ca_bundle_amazon.txt"=>"SSL.com CA Bundle",
                        "sslcom_free_ca_bundle_amazon.txt"=>"Free SSL.com CA Bundle",
                        "sslcom_high_assurance_ca_bundle_amazon.txt"=>"High Assurance SSL.com CA Bundle",
                        "sslcom_ev_ca_bundle.txt_amazon"=>"EV SSL.com CA Bundle",
                        "free_ssl_ca_bundle.txt_amazon"=>"Free SSL.com CA Bundle",
                        "trial_ssl_ca_bundle.txt_amazon"=>"Trial SSL.com CA Bundle",
                        "COMODOAddTrustServerCA.crt"=>"Intermediate CA Certificate",
                        "SSLcomPremiumEVCA_1.crt"=>"Intermediate CA Certificate",
                        "SSLcomAddTrustSSLCA.crt"=>"Intermediate CA Certificate",
                        "SSLcomFreeSSLCA.crt"=>"Intermediate CA Certificate",
                        "COMODOExtendedValidationSecureServerCA.crt"=>"Intermediate CA Certificate",
                        "EntrustSecureServerCA.crt"=>"Root CA Certificate",
                        "USERTrustLegacySecureServerCA.crt"=>"Intermediate CA Certificate"},
                      sha2_sslcom_2014: {
                        dir: "sha2_sslcom_2014",
                        labels: {
                          "AddTrustExternalCARoot.crt"=>"Root CA Certificate",
                          "USERTrustRSAAddTrustCA.crt"=>"Intermediate CA Certificate",
                          "USERTrustRSACertificationAuthority.crt"=>"Root CA Certificate",
                          "SSLcomClientAuthenticationandEmailCA_2.crt"=>"Intermediate CA Certificate",
                          "SSLcomPremiumEVCA_2.crt"=>"Intermediate CA Certificate",
                          "SSLcomDVCA_2.crt"=>"Intermediate CA Certificate",
                          "SSLcomHighAssuranceCA_2.crt"=>"Intermediate CA Certificate",
                          "SSLcomObjectCA_2.crt"=>"Intermediate CA Certificate",
                          "ssl_ca_bundle.txt"=>"High Assurance SSL.com CA Bundle",
                          "sslcom_addtrust_ca_bundle.txt"=>"SSL.com CA Bundle",
                          "sslcom_high_assurance_ca_bundle.txt"=>"High Assurance SSL.com CA Bundle",
                          "sslcom_ev_ca_bundle.txt"=>"EV SSL.com CA Bundle",
                          "ssl_ca_bundle_amazon.txt"=>"High Assurance SSL.com CA Bundle",
                          "sslcom_addtrust_ca_bundle_amazon.txt"=>"SSL.com CA Bundle",
                          "sslcom_high_assurance_ca_bundle_amazon.txt"=>"High Assurance SSL.com CA Bundle",
                          "sslcom_ev_ca_bundle.txt_amazon"=>"EV SSL.com CA Bundle"},
                        contents: {
                          "sslcom_dv.txt" => %w(AddTrustExternalCARoot.crt USERTrustRSAAddTrustCA.crt SSLcomDVCA_2.crt),
                          "sslcom_ov.txt" => %w(AddTrustExternalCARoot.crt USERTrustRSAAddTrustCA.crt SSLcomHighAssuranceCA_2.crt),
                          "sslcom_ev.txt" => %w(AddTrustExternalCARoot.crt USERTrustRSAAddTrustCA.crt SSLcomPremiumEVCA_2.crt),
                          "sslcom_dv_amazon.txt" => %w(SSLcomDVCA_2.crt USERTrustRSAAddTrustCA.crt AddTrustExternalCARoot.crt),
                          "sslcom_ov_amazon.txt" => %w(SSLcomHighAssuranceCA_2.crt USERTrustRSAAddTrustCA.crt AddTrustExternalCARoot.crt),
                          "sslcom_ev_amazon.txt" => %w(SSLcomPremiumEVCA_2.crt USERTrustRSAAddTrustCA.crt AddTrustExternalCARoot.crt),
                          "ssl_ca_bundle.txt"=>%w(USERTrustRSAAddTrustCA.crt SSLcomHighAssuranceCA_2.crt),
                          "ssl_ca_bundle_amazon.txt"=>%w(SSLcomHighAssuranceCA_2.crt USERTrustRSAAddTrustCA.crt),
                          "sslcom_addtrust_ca_bundle.txt"=>%w(USERTrustRSAAddTrustCA.crt SSLcomDVCA_2.crt),
                          "sslcom_addtrust_ca_bundle_amazon.txt"=>%w(SSLcomDVCA_2.crt USERTrustRSAAddTrustCA.crt),
                          "sslcom_high_assurance_ca_bundle.txt"=>%w(USERTrustRSAAddTrustCA.crt SSLcomHighAssuranceCA_2.crt),
                          "sslcom_high_assurance_ca_bundle_amazon.txt"=>%w(SSLcomHighAssuranceCA_2.crt USERTrustRSAAddTrustCA.crt),
                          "sslcom_ev_ca_bundle.txt"=>%w(USERTrustRSAAddTrustCA.crt SSLcomPremiumEVCA_2.crt),
                          "sslcom_ev_ca_bundle.txt_amazon"=>%w(SSLcomPremiumEVCA_2.crt USERTrustRSAAddTrustCA.crt)}}}}


  scope :public, where{(product != 'mssl') & (serial =~ "%sslcom%") & (title << Settings.excluded_titles)}
  scope :sitemap, where{(product != 'mssl') & (product !~ '%tr')}
  scope :for_sale, where{(product != 'mssl') & (serial =~ "%sslcom%")}

  def self.map_to_legacy(description, mapping=nil)
    [MAP_TO_TRIAL,MAP_TO_OV,MAP_TO_EV,MAP_TO_WILDCARD,MAP_TO_UCC].each do |m|
      type = mapping=='renew' ? 1 : 2
      return Certificate.find_by_product(m[type]) if m[0].include?(description)
    end
  end

  def price=(amount)
    self.amount = amount.gsub(/\./,"").to_i
  end

  def api_product_code
    ApiCertificateCreate_v1_4::PRODUCTS.find{|k,v|
      serial =~ Regexp.new(v)
    }[0].to_s
  end

  def items_by_duration
    product_variant_groups.duration.map(&:product_variant_items).
        flatten.sort{|a,b|a.value.to_i <=> b.value.to_i}
  end

  def pricing(certificate_order,certificate_content)
    ratio = certificate_order.signed_certificates.try(:last) ? certificate_order.duration_remaining : 1
    durations=[]
    result={}
    num_durations.times do |i|
      durations <<
          if is_ucc?
            tiers=[]
            num_domain_tiers.times do |j|
              tiers << ((items_by_domains(true)[i][j].price*((j==0)?3:1))*ratio).format

            end
            tiers
          else
            (items_by_duration[i].price*ratio).format
          end
    end
    result.merge!(durations: durations)
    if is_ucc? || is_wildcard?
      licenses=[]
      num_durations.times do |i|
        licenses << (items_by_server_licenses[i].price*ratio).format
      end
      result.merge!(licenses: licenses, domains: certificate_content.domains)
    end
    result
  end

  # use multi_dim to return a multi dimension array of domain types
  def items_by_domains(multi_dim=false)
    if is_ucc?
      unless multi_dim
        product_variant_groups.domains.map(&:product_variant_items).flatten
      else
        unless is_ev?
          product_variant_items.where{serial=~"%yrdm%"}.flatten.zip(
              product_variant_items.where{serial=~"%yradm%"}.flatten,
              product_variant_items.where{serial=~"%yrwcdm%"}.flatten)
        else
          product_variant_items.where{serial=~"%yrdm%"}.flatten.zip(
              product_variant_items.where{serial=~"%yradm%"}.flatten)
        end
      end
    end
  end

  def items_by_server_licenses
    product_variant_groups.server_licenses.map(&:product_variant_items).flatten if
      (is_ucc? || is_wildcard?)
  end

  def first_domains_tiers
    if is_ucc?
      items_by_domains(true).transpose[0]
    end
  end

  def num_durations
    if is_ucc?
      items_by_domains.size / num_domain_tiers
    else
      items_by_duration.size
    end
  end

  def num_domain_tiers
    if is_ucc?
      if is_ev? or is_premium_ssl?
        NUM_DOMAINS_TIERS.to_i - 1
      else
        NUM_DOMAINS_TIERS.to_i
      end
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

  def is_client?
    product.include?('personal')
  end

  def is_client_basic?
    product_root=~/basic$/
  end

  def is_client_pro?
    product_root=~/pro$/
  end

  def is_client_business?
    product_root=~/business$/
  end

  def is_client_enterprise?
    product_root=~/enterprise$/
  end

  def requires_company_info?
    is_client_business? || is_client_enterprise? || is_server? || is_code_signing?
  end

  def is_server?
    !(is_client? || is_code_signing?)
  end

  def is_wildcard?
    product.include?('wildcard')
  end

  def is_ev?
    product.include?('ev')
  end

  def is_ov?
    product.include?('high_assurance')
  end

  def is_browser_generated_capable?
    is_code_signing? || is_client?
  end

  def is_code_signing?
    product.include?('code_signing') || product.include?('code-signing')
  end

  def is_personal?
    product.include?('personal')
  end

  def is_document_signing?
    product.include?('document_signing')
  end

  def is_premium_ssl?
    product_root=="premiumssl"
  end

  def is_dv?
    product.include?('free')
  end

  def is_dv_or_basic?
    (serial =~ /^dv/ || serial =~ /^basic/) if serial
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
    (is_ev? or is_premium_ssl?) ? false : true
    #true
    #allow_wildcard_ucc
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

  def subscriber_agreement_content
    File.read(subscriber_agreement[:location])
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

  def skip_verification?
    false
  end

  # options = {bundles: Certificate::BUNDLES[:comodo][:sha2_sslcom_2014]}
  def self.generate_ca_certificates(options)
    dir=Settings.intermediate_certs_path+options[:bundles][:dir]+"/"
    options[:bundles][:contents].each do |k,v|
      certfile="#{dir}#{k}"
      File.open(certfile, 'wb') do |f|
        tmp=""
        v.each do |file_name|
          file=File.new("#{dir}"+file_name.strip, "r")
          tmp << file.readlines.join("")
        end
        f.write tmp
      end
    end
  end

  def order_description
    try(:description_with_tier) ? certificate_type(self) : description_with_tier
  end

  private

  # renames 'product' field for certificate including the reseller tiers
  def self.rename(oldname, newname)
    certificates = Certificate.unscoped.where{product =~ "%#{oldname}%"}
    certificates.each {|certificate| certificate.update_column :product, certificate.product.gsub(oldname, newname)}
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

  # sslcomevucc256ssl1yrdm - initial 3 domains
  # sslcomevucc256ssl1yradm - additional domains
  # each column is an incremented a year and represents cost of 3 domains
  #
  # use root like sslcomevucc256ssl1yr
  def self.change_domain_pricing(pvi)
    years = 2 # 5 for standard
    # ev ssl
    price_adjusts={"#{pvi}dm".to_sym => [13300, 21280], # initial 3 domains
                   "#{pvi}dm1tr".to_sym => [13300, 21280],
                   "#{pvi}dm2tr".to_sym => [10640, 17024],
                   "#{pvi}dm3tr".to_sym => [9975, 15960],
                   "#{pvi}dm4tr".to_sym => [9310, 14896],
                   "#{pvi}dm5tr".to_sym => [7980, 12768],
                   "#{pvi}adm".to_sym => [12900, 20640], # domains after 3rd
                   "#{pvi}adm1tr".to_sym => [12900, 20640],
                   "#{pvi}adm2tr".to_sym => [10320, 16512],
                   "#{pvi}adm3tr".to_sym => [9675, 15480],
                   "#{pvi}adm4tr".to_sym => [9030, 14448],
                   "#{pvi}adm5tr".to_sym => [7740, 12384]
    }
    # standard ssl
    # price_adjusts={"#{pvi}".to_sym => [9900, 17820, 25245, 31680, 37125],
    #                "#{pvi}1tr".to_sym => [9900, 17820, 25245, 31680, 37125],
    #                "#{pvi}2tr".to_sym => [7920, 14256, 20196, 25344, 29700],
    #                "#{pvi}3tr".to_sym => [7425, 13365, 18934, 23760, 27844],
    #                "#{pvi}4tr".to_sym => [6831, 12296, 17419, 21859, 25616],
    #                "#{pvi}5tr".to_sym => [5940, 10692, 15147, 19008, 22275]
    # }
    price_adjusts.each do |k,v|
      serials=[]
      1.upto(years){|i|serials<<k.to_s.gsub(/1yr/, i.to_s+"yr")}
      serials.each_with_index {|s, i|ProductVariantItem.find_by_serial(s).update_attribute(:amount, (v[i]).ceil)}
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
  
  def self.create_code_signing
    c=Certificate.public.find_by_product "high_assurance"
    certs = c.duplicate_tiers "codesigning256sslcom", "ov256ssl", "codesigning256ssl"
    title = "Code Signing"
    description={
        "certificate_type" => title,
                  "points" => "<div class='check'>organization validation</div>
                               <div class='check'>results in higher sales conversion</div>
                               <div class='check'>$150,000 USD insurance guaranty</div>
                               <div class='check'>activates SSL Secure Site Seal</div>
                               <div class='check'>2048 bit public key encryption</div>
                               <em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>
                               <div class='check'>quick issuance</div>
                               <div class='check'>30 day unconditional refund</div>
                               <div class='check'>24 hour support</div>
                               <div class='check'>unlimited reissuances</div>",
        "validation_level" => "organization",
                 "summary" => "for securing installable apps and plugins",
                    "abbr" => title
    }
    certs.each do |c|
      c.update_attributes title: title,
                          description: description,
                          product: c.product.gsub(/^high_assurance/, "code_signing"),
                          icons: c.icons.merge!("main"=> "gold_lock_lg.gif")
    end
    price_adjusts={sslcomcodesigning256ssl1yr: [12900, 23220, 32895, 41280, 48375, 54180, 58695, 61920, 63855, 64500], 
                   sslcomcodesigning256ssl1yr1tr: [12900, 23220, 32895, 41280, 48375, 54180, 58695, 61920, 63855, 64500],
                   sslcomcodesigning256ssl1yr2tr: [10320, 18576, 26316, 33024, 38700, 43344, 46956, 49536, 51084, 51600],
                   sslcomcodesigning256ssl1yr3tr: [9675, 17415, 24671, 30960, 36281, 40635, 44021, 46440, 47891, 48375],
                   sslcomcodesigning256ssl1yr4tr: [9030, 16254, 23026, 28896, 33862, 37926, 41086, 43344, 44698, 45150],
                   sslcomcodesigning256ssl1yr5tr: [7740, 13932, 19737, 24768, 29025, 32508, 35217, 37152, 38313, 38700]
    }
    price_adjusts.each do |k,v|
      serials=[]
      1.upto(10){|i|serials<<k.to_s.gsub(/1yr/, i.to_s+"yr")}
      serials.each_with_index {|s, i|
        if ProductVariantItem.find_by_serial(s)
          ProductVariantItem.find_by_serial(s).update_attribute(:amount, v[i])
        else
          if s.last(3)=~/\d+tr/ #assume a reseller tier
            pvg = certs.find{|c|c.serial.last(3)==s.last(3)}.product_variant_groups.last
          else #assume non reseller
            pvg = certs.first.product_variant_groups.last
          end
          pvi = pvg.product_variant_items.last
          years = i+1
          pvg.product_variant_items.create(serial: s, amount: v[i], title: pvi.title.gsub(/\d/,years.to_s),
            status: pvi.status, description: pvi.description.gsub(/\d/,years.to_s),
            text_only_description: pvi.text_only_description.gsub(/\d/,years.to_s), display_order: years.to_s,
            item_type: pvi.item_type, value: 365*years, published_as: pvi.published_as)
        end
      }
    end
  end

  def self.create_email_certs
    products=[{serial_root: "personalbasic",title: "Personal Basic",validation_type: "class 1",
               summary: "for authenticating and encrypting email and well as client services",
               product: "personal-basic",
               price_adjusts:{sslcompersonalbasic256ssl1yr: [3000, 4500, 6000],
                              sslcompersonalbasic256ssl1yr1tr: [3000, 4500, 6000],
                              sslcompersonalbasic256ssl1yr2tr: [3000, 4500, 6000],
                              sslcompersonalbasic256ssl1yr3tr: [3000, 4500, 6000],
                              sslcompersonalbasic256ssl1yr4tr: [3000, 4500, 6000],
                              sslcompersonalbasic256ssl1yr5tr: [3000, 4500, 6000]
               }},
              {serial_root: "personalbusiness",title: "Personal Business",validation_type: "class 2",
               summary: "for authenticating and encrypting email and well as client services",
               product: "personal-business",
               price_adjusts:{sslcompersonalbusiness256ssl1yr: [9000, 12000, 15000],
                              sslcompersonalbusiness256ssl1yr1tr: [9000, 12000, 15000],
                              sslcompersonalbusiness256ssl1yr2tr: [9000, 12000, 15000],
                              sslcompersonalbusiness256ssl1yr3tr: [9000, 12000, 15000],
                              sslcompersonalbusiness256ssl1yr4tr: [9000, 12000, 15000],
                              sslcompersonalbusiness256ssl1yr5tr: [9000, 12000, 15000]
               }},
              {serial_root: "personalpro",title: "Personal Pro",validation_type: "class 2",
               summary: "for authenticating and encrypting email and well as client services",
               product: "personal-pro",
               price_adjusts:{sslcompersonalpro56ssl1yr: [7000, 8000, 9000],
                              sslcompersonalpro256ssl1yr1tr: [7000, 8000, 9000],
                              sslcompersonalpro256ssl1yr2tr: [7000, 8000, 9000],
                              sslcompersonalpro256ssl1yr3tr: [7000, 8000, 9000],
                              sslcompersonalpro256ssl1yr4tr: [7000, 8000, 9000],
                              sslcompersonalpro256ssl1yr5tr: [7000, 8000, 9000]
               }},
              {serial_root: "personalenterprise",title: "Personal Enterprise",validation_type: "class 2",
               summary: "for authenticating and encrypting email and well as client services",
               product: "personal-enterprise",
               price_adjusts:{sslcompersonalenterprise256ssl1yr: [24900, 49900, 59900],
                              sslcompersonalenterprise256ssl1yr1tr: [24900, 49900, 59900],
                              sslcompersonalenterprise256ssl1yr2tr: [24900, 49900, 59900],
                              sslcompersonalenterprise256ssl1yr3tr: [24900, 49900, 59900],
                              sslcompersonalenterprise256ssl1yr4tr: [24900, 49900, 59900],
                              sslcompersonalenterprise256ssl1yr5tr: [24900, 49900, 59900]
               }}]
    products.each do |p|
      c=Certificate.public.find_by_product "high_assurance"
      certs = c.duplicate_tiers "#{p[:serial_root]}256sslcom", "ov256ssl", "#{p[:serial_root]}256ssl"
      title = p[:title]
      description={
          "certificate_type" => title,
          "points" => "",
          "validation_level" => p[:validation_type],
          "summary" => p[:summary],
          "abbr" => title
      }
      certs.each do |c|
        c.update_attributes title: title,
                            description: description,
                            product: c.product.gsub(/^high_assurance/, p[:product]),
                            icons: c.icons.merge!("main"=> "gold_lock_lg.gif")
      end
      certs.each{ |c| c.product_variant_items.where{display_order > 3}.destroy_all}
      p[:price_adjusts].each do |k,v|
        serials=[]
        num_years=3
        1.upto(num_years){|i|serials<<k.to_s.gsub(/1yr/, i.to_s+"yr")}
        serials.each_with_index {|s, i|
          if ProductVariantItem.find_by_serial(s)
            ProductVariantItem.find_by_serial(s).update_attribute(:amount, v[i])
          else
            if s.last(3)=~/\d+tr/ #assume a reseller tier
              pvg = certs.find{|c|c.serial.last(3)==s.last(3)}.product_variant_groups.last
            else #assume non reseller
              pvg = certs.first.product_variant_groups.last
            end
            pvi = pvg.product_variant_items.last
            years = i+1
            pvg.product_variant_items.create(serial: s, amount: v[i], title: pvi.title.gsub(/\d/,years.to_s),
              status: pvi.status, description: pvi.description.gsub(/\d/,years.to_s),
              text_only_description: pvi.text_only_description.gsub(/\d/,years.to_s),
              display_order: years.to_s,
              item_type: pvi.item_type, value: 365*years, published_as: pvi.published_as)
          end
        }
      end
    end
  end

  def self.purge(serial_snippet)
    Certificate.where{serial=~"%#{serial_snippet}%"}.each do |c|
      c.product_variant_groups.each do |pvg|
        pvg.product_variant_items.each do |pvi|
          pvi.destroy
        end
        pvg.destroy
      end
      c.destroy
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

  def self.reduce_years(title="assureguard-dv%", days=1095)
    self.where{product =~ title}.each do |c|
      c.product_variant_items.where{value > days}.each{|pvi|pvi.delete}
    end
  end

  # title - a specific tier of products
  # prices - an ordered array of prices in cents USD. For ucc, use a 2 dimensional array with the structure
  #          [[1-3 domain price, 4+ domain price, wildcard price]] in increasing order of years
  #
  # ie Certificate.change_prices "assureguard-ucc", [[18500,18500,49500],[31400,31500,82500],[43466,43500,116500]]
  #    Certificate.change_prices("assureguard-evucc", [[37500,37500],[58500,58500]])

  def self.change_prices(title="assureguard-dv", prices=[6800,11500,15200])
    self.where{product == title}.each do |c|
      if c.product_variant_items.where{item_type == "duration"}.count>0 #assume non ucc
        c.product_variant_items.where{item_type == "duration"}.each_with_index{|pvi,i| pvi.update_column :amount, prices[i]}
      elsif c.product_variant_items.where{item_type == "ucc_domain"}.count>0 #assume ucc
        c.product_variant_items.where{item_type == "ucc_domain"}.each{|pvi|
          i = pvi.value.to_i/365
          price = if pvi.description=~/3 domains/i
            prices[i-1][0]
          elsif pvi.description=~/wildcard/i
            prices[i-1][2]
          else
            prices[i-1][1]
          end
          pvi.update_column :amount, price
        }
      end
    end
  end

end