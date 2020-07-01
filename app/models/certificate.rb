# == Schema Information
#
# Table name: certificates
#
#  id                    :integer          not null, primary key
#  allow_wildcard_ucc    :boolean
#  description           :text(65535)
#  display_order         :string(255)
#  icons                 :string(255)
#  product               :string(255)
#  published_as          :string(16)       default("draft")
#  roles                 :string(255)      default("--- []")
#  serial                :string(255)
#  special_fields        :string(255)      default("--- []")
#  status                :string(255)
#  summary               :text(65535)
#  text_only_description :text(65535)
#  text_only_summary     :text(65535)
#  title                 :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  reseller_tier_id      :integer
#
# Indexes
#
#  index_certificates_on_reseller_tier_id  (reseller_tier_id)
#

class Certificate < ApplicationRecord
  extend Memoist
  include CertificateType
  include PriceView
  include Filterable
  include Sortable
  include Pagable

  has_many    :product_variant_groups, :as => :variantable, dependent: :destroy
  has_many    :product_variant_items, through: :product_variant_groups, dependent: :destroy
  has_many    :sub_order_items, through: :product_variant_items
  has_many    :validation_rulings, :as=>:validation_rulable
  has_many    :validation_rules, :through => :validation_rulings
  has_and_belongs_to_many :products
  has_many    :cas_certificates, dependent: :destroy
  has_many    :cas, through: :cas_certificates

  acts_as_publishable :live, :draft, :discontinue_sell
  belongs_to  :reseller_tier

  serialize   :icons
  serialize   :description
  serialize   :display_order
  serialize   :title
  serialize   :special_fields
  preference  :certificate_chain, :string

  accepts_nested_attributes_for :product_variant_groups, allow_destroy: false

  ROLES = ResellerTier.pluck(:roles).compact.push('Registered').sort

  NUM_DOMAINS_TIERS = 3
  UCC_INITIAL_DOMAINS_BLOCK = 3
  UCC_MAX_DOMAINS = 800

  FREE_CERTS_CART_LIMIT = 5

  DOMAINS_TEXTAREA_SEPARATOR=/[\s\n\,\+]+/

  USERTRUST_EV_SUBSCRIBER_AGREEMENT="https://cdn.ssl.com/app/uploads/2015/07/ssl_certificate_subscriber_agreement.pdf"
  USERTRUST_EV_AUTHORIZATION="https://cdn.ssl.com/app/uploads/2015/07/ev-request-form-simplified.pdf"
  SSLCOM_EV_SUBSCRIBER_AGREEMENT="https://cdn.ssl.com/app/uploads/2017/06/SSL_com_EV_Subscriber_Agreement.pdf"
  SSLCOM_EV_AUTHORIZATION="https://cdn.ssl.com/app/uploads/2018/03/SSL_com_EV_Request_Form_1.1.pdf"
  SSLCOM_SUBSCRIBER_AGREEMENT="https://cdn.ssl.com/subscriber_agreement"
  SSLCOM_CP_CPS="https://cdn.ssl.com/repository/SSLcom-CPS.pdf"

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
  # Comodo prods:
  # Essential Free SSL = 342
  # Essential SSL = 301
  # Essential SSL Wildcard = 343
  # Positive SSL MDC = 279
  # InstantSSL Wildcard = 35
  # 43 was the old trial cert
  COMODO_PRODUCT_MAPPINGS =
      {"free"=> 342, "high_assurance"=>24, "wildcard"=>35, "ev"=>337,
       "ucc"=>361, "evucc"=>410}
  COMODO_PRODUCT_MAPPINGS_SSL_COM =
      {"free"=> 342,
       Settings.subca_mapping.ov.product=>Settings.send_dv_first ? 301 : 24,
       Settings.subca_mapping.wildcard.product=>343,
       Settings.subca_mapping.ev.product=> Settings.send_dv_first ? 301 : 337,
       Settings.subca_mapping.ucc.product=>279,
       Settings.subca_mapping.evucc.product=> Settings.send_dv_first ? 279 : 410,
       "premiumssl"=>279,
       Settings.subca_mapping.dv.product=>301}

  # ssl_ca_bundle.txt is the same as COMODOHigh-AssuranceSecureServerCA.crt
  # file_name => description (as displayed in emails)
  COMODO_BUNDLES = {"AAACertificateServices.crt"=>"Root CA Certificate",
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
                        "AAACertificateServices.crt"=>"Root CA Certificate",
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
                        "AAACertificateServices.crt"=>"Root CA Certificate",
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
                          "AAACertificateServices.crt"=>"Root CA Certificate",
                          "USERTrustRSAAAACA.crt"=>"Intermediate CA Certificate",
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
                          "sslcom_dv.txt" => %w(AAACertificateServices.crt USERTrustRSAAAACA.crt SSLcomDVCA_2.crt),
                          "sslcom_ov.txt" => %w(AAACertificateServices.crt USERTrustRSAAAACA.crt SSLcomHighAssuranceCA_2.crt),
                          "sslcom_ev.txt" => %w(AAACertificateServices.crt USERTrustRSAAAACA.crt SSLcomPremiumEVCA_2.crt),
                          "sslcom_dv_amazon.txt" => %w(SSLcomDVCA_2.crt USERTrustRSAAAACA.crt AAACertificateServices.crt),
                          "sslcom_ov_amazon.txt" => %w(SSLcomHighAssuranceCA_2.crt USERTrustRSAAAACA.crt AAACertificateServices.crt),
                          "sslcom_ev_amazon.txt" => %w(SSLcomPremiumEVCA_2.crt USERTrustRSAAAACA.crt AAACertificateServices.crt),
                          "ssl_ca_bundle.txt"=>%w(USERTrustRSAAAACA.crt SSLcomHighAssuranceCA_2.crt),
                          "ssl_ca_bundle_amazon.txt"=>%w(SSLcomHighAssuranceCA_2.crt USERTrustRSAAAACA.crt),
                          "sslcom_addtrust_ca_bundle.txt"=>%w(USERTrustRSAAAACA.crt SSLcomDVCA_2.crt),
                          "sslcom_addtrust_ca_bundle_amazon.txt"=>%w(SSLcomDVCA_2.crt USERTrustRSAAAACA.crt),
                          "sslcom_high_assurance_ca_bundle.txt"=>%w(USERTrustRSAAAACA.crt SSLcomHighAssuranceCA_2.crt),
                          "sslcom_high_assurance_ca_bundle_amazon.txt"=>%w(SSLcomHighAssuranceCA_2.crt USERTrustRSAAAACA.crt),
                          "sslcom_ev_ca_bundle.txt"=>%w(USERTrustRSAAAACA.crt SSLcomPremiumEVCA_2.crt),
                          "sslcom_ev_ca_bundle.txt_amazon"=>%w(SSLcomPremiumEVCA_2.crt USERTrustRSAAAACA.crt)}}}}


  scope :base_products, ->{where{reseller_tier_id == nil}}
  scope :available, ->{where{(product != 'mssl') & (serial =~ "%sslcom%") & (title << Settings.excluded_titles)}}
  scope :sitemap, ->{where{(product != 'mssl') & (product !~ '%tr')}}
  scope :not_mssl, -> { where.not(product: 'mssl') }
  scope :sslcom, -> { where("serial LIKE ?", "%sslcom%")}
  scope :for_sale, -> { unscoped.not_mssl.sslcom }
  
  def self.get_smime_client_products(tier=nil)
    cur_tier = tier.blank? ? '' : "#{tier}tr"
    Certificate.available.where(
      "product REGEXP ?",
      "^personal.*(basic|pro|business|enterprise|naesb-basic)#{cur_tier}$"
    )
  end

  def self.map_to_legacy(description, mapping=nil)
    [MAP_TO_TRIAL,MAP_TO_OV,MAP_TO_EV,MAP_TO_WILDCARD,MAP_TO_UCC].each do |m|
      type = mapping=='renew' ? 1 : 2
      return Certificate.find_by_product(m[type]) if m[0].include?(description)
    end
  end

  def self.index_filter(params)
    filters = {}
    p = params
    filters[:serial] = { 'LIKE' => p[:serial] } unless p[:serial].blank?
    filters[:title] = { 'LIKE' => p[:title] } unless p[:title].blank?
    filters[:product] = { 'LIKE' => p[:product] } unless p[:product].blank?
    filters[:description] = { 'LIKE' => p[:description] } unless p[:description].blank?
    unless p[:created_at_type].blank? || p[:created_at].blank?
      operator = COMPARISON[p[:created_at_type].to_sym]
      filters[:created_at] = { operator => DateTime.parse(p[:created_at]).beginning_of_day }
    end
    unless p[:updated_at_type].blank? || p[:updated_at].blank?
      operator = COMPARISON[p[:updated_at_type].to_sym]
      filters[:updated_at] = { operator => DateTime.parse(p[:updated_at]).end_of_day }
    end
    filters[:allow_wildcard_ucc] = { '=' => p[:wildcard] } unless p[:wildcard].blank?
    filters[:reseller_tier_id] = { '=' => p[:reseller_tier_id] } unless p[:reseller_tier_id].blank?
    result = filter(filters)
    result
  end

  def cached_product_variant_items(options={})
    @cpvi ||= ProductVariantItem.unscoped.where(id:
      (Rails.cache.fetch("#{cache_key}/cached_product_variant_items/#{options.to_s}") do
        if options[:by_serial]
          product_variant_items.where{serial=~"%#{options[:by_serial]}%"}
        else
          product_variant_items
        end.pluck(:id)
    end))
  end
  memoize :cached_product_variant_items

  def role_can_manage
    Role.get_role_id Role::RA_ADMIN
  end

  def price=(amount)
    self.amount = amount.gsub(/\./,"").to_i
  end

  def api_product_code
    ApiCertificateRequest::PRODUCTS.find{|k,v|
      serial =~ Regexp.new('^'+v)
    }[0].to_s
  end

  def items_by_duration
    ProductVariantItem.where(id: (Rails.cache.fetch("#{cache_key}/items_by_duration") do
      product_variant_groups.includes(:product_variant_items).duration.map(&:product_variant_items).
          flatten.sort{|a,b|a.value.to_i <=> b.value.to_i}.map(&:id)
    end))
  end
  memoize :items_by_duration

  def pricing(certificate_order,certificate_content)
    Rails.cache.fetch("#{cache_key}/#{certificate_order.try(:cache_key)}/#{certificate_content.try(:domains_hash)}", expires_in: 1.hour) do
      ratio = certificate_order.signed_certificate ? certificate_order.duration_remaining : 1
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
        result.merge!(licenses: licenses, domains: certificate_content.try(:domains))
      end
      result.merge!(product: product)
    end
  end

  # use multi_dim to return a multi dimension array of domain types
  def items_by_domains(multi_dim=false)
    if is_ucc?
      unless multi_dim
        product_variant_groups.domains.includes(:product_variant_items).map(&:product_variant_items).flatten
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
  memoize :items_by_domains

  def items_by_server_licenses
    product_variant_groups.server_licenses.includes(:product_variant_items).map(&:product_variant_items).flatten if
      (is_ucc? || is_wildcard?)
  end
  memoize :items_by_server_licenses

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
    @fcpvi ||= cached_product_variant_items.first
  end

  def last_duration
    @lcpvi ||= cached_product_variant_items.last
  end

  # is is true for SAN and EV SAN certs
  def is_ucc?
    product.include?('ucc') || product.include?('premiumssl')
  end

  # true for EV SAN only
  def is_evucc?
    product =~ /\Aevucc/
  end

  def admin_submit_csr?
    is_evcs? or
    is_cs? or
    is_smime_or_client?
  end

  def is_wildcard?
    product =~ /wildcard/
  end

  def is_basic?
    product =~ /basic/
  end

  def is_high_assurance?
    product =~ /high_assurance/
  end

  def is_browser_generated_capable?
    is_code_signing? || is_client?
  end

  def is_personal?
    product.include?('personal')
  end

  def is_premium_ssl?
    product =~ /\Apremiumssl/
  end

  alias_method "is_dv_or_basic?".to_sym, "is_dv?".to_sym

  def is_free?
    product =~ /\Afree/
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
    Certificate.available.find_by_product(product_root+tier+'tr')
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
    get_root(self.product)
  end

  def serial_root
    get_root(self.serial)
  end

  def to_param
    product_root
  end

  def untiered
    if reseller_tier.blank?
      self
    else
      Certificate.available.find_by_product product_root
    end
  end

  def self.root_products
    Certificate.base_products.available.sort{|a,b|
    a.display_order['all'] <=> b.display_order['all']}
  end

  def self.tiered_products(tier)
    Certificate.available.sort{|a,b|
    a.display_order['all'] <=> b.display_order['all']}.find_all{|c|
        c.product=~Regexp.new(tier)}
  end

  def has_locked_registrant?
    is_code_signing? || is_ev? || is_ov?
  end

  def subscriber_agreement
    SUBSCRIBER_AGREEMENTS[product_root.to_sym]
  end

  def subscriber_agreement_content
    File.read(subscriber_agreement[:location])
  end

  def duration_in_days(duration)
    if is_ucc?
      index = duration.to_i
      items_by_domains.select{|n|n.display_order==index}.last.value
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

  def self.xcert_certum(x509_certificate,tagged_xcert=false)
    case x509_certificate.serial.to_s
    when "8875640296558310041"
      tagged_xcert ? SignedCertificate.enclose_with_tags(CERTUM_XSIGN) : CERTUM_XSIGN
    when "6248227494352943350","5688664355526928916"
      tagged_xcert ? SignedCertificate.enclose_with_tags(CERTUM_XSIGN_EV) : CERTUM_XSIGN_EV
    when "8495723813297216424"
      tagged_xcert ? SignedCertificate.enclose_with_tags(RSA_TO_ECC_XSIGN) : RSA_TO_ECC_XSIGN
    when "3182246526754555285"
      tagged_xcert ? SignedCertificate.enclose_with_tags(RSA_TO_ECC_EV_XSIGN) : RSA_TO_ECC_EV_XSIGN
    else
      x509_certificate.to_s
    end
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

  # this method duplicates, modifies or adds reseller tiers to a certificate
  # deep level copying function, copies own attributes and then duplicates the sub groups and items
  # options[:new_serial] - new serial number, the numbered reseller tier will be preserved
  # options[:old_pvi_serial] - old product_variant_item serial number
  # options[:new_pvi_serial] - new product_variant_item serial number
  # options[:reseller_tier_label] - label of the reseller tier to create or update
  # options[:discount_rate] - reduce price by this much
  def duplicate(options)
    now=DateTime.now
    new_cert = self.dup
    new_cert.product="#{self.product}"
    if options[:new_serial] # changing serial
      m=self.serial.match(/.*?((\d+|\-.+?)tr)\z/)
      new_cert.serial=options[:new_serial]+(m.blank? ? "" : m[1])
    elsif options[:reseller_tier_label]
      new_cert.product<<"-#{options[:reseller_tier_label]}tr"
      if Certificate.find_by_serial("#{self.serial}-#{options[:reseller_tier_label]}tr") # adding reseller tier
        new_cert = Certificate.find_by_serial("#{self.serial}-#{options[:reseller_tier_label]}tr") # update
      else
        new_cert.serial="#{self.serial}-#{options[:reseller_tier_label]}tr" # create reseller tier
      end
    end
    new_cert.save
    self.product_variant_groups.each do |pvg|
      new_pvg = pvg.dup
      new_cert.product_variant_groups << new_pvg
      pvg.product_variant_items.each_with_index do |pvi, i|
        if options[:product].blank? or i < options[:product][:price_adjusts].first[1].count
          new_pvi=pvi.dup
          if options[:old_pvi_serial] and options[:new_pvi_serial]
            new_pvi.serial=pvi.serial.gsub(options[:old_pvi_serial], options[:new_pvi_serial])
          elsif options[:reseller_tier_label]
            if ProductVariantItem.find_by_serial("#{pvi.serial}-#{options[:reseller_tier_label]}tr") # adding reseller tier
              new_pvi = ProductVariantItem.find_by_serial("#{pvi.serial}-#{options[:reseller_tier_label]}tr") # update
            else
              new_pvi.serial="#{pvi.serial}-#{options[:reseller_tier_label]}tr" # create reseller tier
            end
          end
          new_pvi.amount=((new_pvi.amount || 0)*options[:discount_rate]).ceil if options[:discount_rate]
          new_pvg.product_variant_items << new_pvi
          unless pvi.sub_order_item.blank?
            if new_pvi.sub_order_item.blank?
              new_pvi.sub_order_item=pvi.sub_order_item.dup
            end
            new_pvi.sub_order_item.amount=((new_pvi.sub_order_item.amount || 0)*options[:discount_rate]).ceil if options[:discount_rate]
            new_pvi.sub_order_item.save
          end
        end
      end
    end
    new_cert
  end

  def get_root(extract_from)
    if extract_from =~ /-?\dtr\z/
      extract_from.gsub(/-?\dtr\z/,"")
    elsif extract_from =~ /.+(-.+?tr)\z/
      extract_from.sub $1, ""
    else
      extract_from
    end
  end

  # this method duplicates the base certificate product along with all reseller_tiers
  def duplicate_w_tiers(options)
    sr = "#{self.serial_root}%"
    Certificate.where{serial =~ sr}.map {|c| c.duplicate(options)}
  end

  # this method duplicates the base certificate product along with all standard 5 reseller_tiers
  def duplicate_standard_tiers(options)
    standard = "#{self.serial_root}%"
    custom = "#{self.serial_root}-%"
    Certificate.where{serial =~ standard}.where{serial !~ custom}.map {|c|
      c.duplicate(options)}
  end

  def self.list_default_cas
    all.map do |cert|
      [cert.product,cert.cas.default.map(&:id)] unless cert.cas.default.map(&:id).empty?
    end.compact
  end

  def max_duration
    if is_smime_or_client?
      CertificateOrder::CLIENT_MAX_DURATION
    elsif is_code_signing?
      CertificateOrder::CS_MAX_DURATION
    elsif is_ev?
      CertificateOrder::EV_SSL_MAX_DURATION
    elsif is_time_stamping?
      CertificateOrder::TS_MAX_DURATION
    else # assume non EV SSL
      CertificateOrder::SSL_MAX_DURATION
    end
  end

  # use this function to update prices via ResellerTier#update_prices
  def prices_matrix(indexed=true)
    if indexed
      prices={}
      product_variant_items.includes{product_variant_group}.map do |pvi|
        prices.merge!(pvi.id=>[pvi.product_variant_group.variantable(Certificate).title,
                               pvi.product_variant_group.title, pvi.title, pvi.amount])
      end
    else
      prices=[]
      product_variant_items.includes{product_variant_group}.map do |pvi|
        prices<<{variantable_title: pvi.product_variant_group.variantable(Certificate).title,
                 pvg_title: pvi.product_variant_group.title, pvi_title: pvi.title, pvi_amount: pvi.amount}
      end
    end
    prices
  end

  private

  # renames 'product' field for certificate including the reseller tiers
  def self.rename(oldname, newname)
    certificates = Certificate.unscoped.where{product =~ "%#{oldname}%"}
    certificates.each {|certificate| certificate.update_column :product, certificate.product.gsub(oldname, newname)}
  end

  # one-time call to create ssl.com product lines to supplant Comodo Essential SSL
  def self.create_sslcom_products
    %w(evucc ucc ev ov dv wc).each do |serial|
      s = self.serial+"%"
      Certificate.where{serial =~ s}.first.duplicate_standard_tiers serial+"256sslcom"
    end
  end

  # one-time call to create ssl.com premium products
  def self.create_premium_ssl
    c=Certificate.available.find_by_product "ucc"
    certs = c.duplicate_standard_tiers new_serial: "premium256sslcom", old_pvi_serial: "ucc256ssl",
                              new_pvi_serial: "premium256ssl"
    title = "Premium Multi-subdomain SSL"
    description={
        "certificate_type" => "Premium SSL",
                  "points" => "<div class='check'>quick domain validation</div>
                               <div class='check'>results in higher sales conversion</div>
                               <div class='check'>$10,000 USD insurance guarantee</div>
                               <div class='check'>works on MS Exchange or OWA</div>
                               <div class='check'>activates SSL Secure Site Seal</div>
                               <div class='check'>2048 bit public key encryption</div>
                               <em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>
                               <div class='check'>quick issuance</div>
                               <div class='check'>30 day money-back guarantee</div>
                               <div class='check'>24 hour support</div>
                               <div class='check'>unlimited reissuances</div>",
        "validation_level" => "domain",
                 "summary" => "for securing small to medium sites",
                    "abbr" => "Premium SSL"
    }
    certs.each do |c|
      c.update_attributes title: title,
                          description: description,
                          product: c.product.gsub(/\Aucc/, "premiumssl")
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
    c=Certificate.available.find_by_product "high_assurance"
    certs = c.duplicate_standard_tiers new_serial: "basic256sslcom", old_pvi_serial: "ov256ssl", new_pvi_serial: "basic256ssl"
    title = "Basic SSL"
    description={
        "certificate_type" => "Basic SSL",
                  "points" => "<div class='check'>quick domain validation</div>
                               <div class='check'>results in higher sales conversion</div>
                               <div class='check'>$10,000 USD insurance guarantee</div>
                               <div class='check'>activates SSL Secure Site Seal</div>
                               <div class='check'>2048 bit public key encryption</div>
                               <em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>
                               <div class='check'>quick issuance</div>
                               <div class='check'>30 day money-back guarantee</div>
                               <div class='check'>24 hour support</div>
                               <div class='check'>unlimited reissuances</div>",
        "validation_level" => "domain",
                 "summary" => "for securing small sites",
                    "abbr" => "Basic SSL"
    }
    certs.each do |c|
      c.update_attributes title: title,
                          description: description,
                          product: c.product.gsub(/\Ahigh_assurance/, "basicssl"),
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
    c=Certificate.available.find_by_product "high_assurance"
    certs = c.duplicate_standard_tiers new_serial: "codesigning256sslcom", old_pvi_serial: "ov256ssl",
                              new_pvi_serial: "codesigning256ssl"
    title = "Code Signing"
    description={
        "certificate_type" => title,
                  "points" => "<div class='check'>organization validation</div>
                               <div class='check'>results in higher sales conversion</div>
                               <div class='check'>$150,000 USD insurance guarantee</div>
                               <div class='check'>activates SSL Secure Site Seal</div>
                               <div class='check'>2048 bit public key encryption</div>
                               <em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>
                               <div class='check'>quick issuance</div>
                               <div class='check'>30 day money-back guarantee</div>
                               <div class='check'>24 hour support</div>
                               <div class='check'>unlimited reissuances</div>",
        "validation_level" => "organization",
                 "summary" => "for securing installable apps and plugins",
                    "abbr" => title
    }
    certs.each do |c|
      c.update_attributes title: title,
                          description: description,
                          product: c.product.gsub(/\Ahigh_assurance/, "code_signing"),
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

  def self.create_ev_code_signing
    c=Certificate.available.find_by_product "high_assurance"
    certs = c.duplicate_standard_tiers new_serial: "evcodesigning256sslcom", old_pvi_serial: "ov256ssl",
                              new_pvi_serial: "evcodesigning256ssl"
    title = "EV Code Signing"
    description={
        "certificate_type" => title,
                  "points" => "<div class='check'>extended validation</div>
                               <div class='check'>results in higher sales conversion</div>
                               <div class='check'>$2 million USD insurance guarantee</div>
                               <div class='check'>works with Microsoft Smartscreen</div>
                               <div class='check'>2048 bit public key encryption</div>
                               <em style='color:#333;display:block;padding:5px 20px;'>also comes with the following</em>
                               <div class='check'>quick issuance</div>
                               <div class='check'>30 day money-back guarantee</div>
                               <div class='check'>stored on fips 140-2 USB token</div>
                               <div class='check'>24 hour support</div>",
        "validation_level" => "extended",
                 "summary" => "for securing installable apps and plugins",
                    "abbr" => title
    }
    certs.each do |c|
      c.update_attributes title: title,
                          description: description,
                          product: c.product.gsub(/\Ahigh_assurance/, "ev-code-signing"),
                          icons: c.icons.merge!("main"=> "gold_lock_lg.gif")
    end
    price_adjusts={sslcomevcodesigning256ssl1yr: [34900, 59800, 74700],
                   sslcomevcodesigning256ssl1yr1tr: [34900, 59800, 74700],
                   sslcomevcodesigning256ssl1yr2tr: [27920, 47840, 59760],
                   sslcomevcodesigning256ssl1yr3tr: [26175, 44850, 56025],
                   sslcomevcodesigning256ssl1yr4tr: [24430, 41860, 52290],
                   sslcomevcodesigning256ssl1yr5tr: [20940, 35880, 44820]
    }
    price_adjusts.each do |k,v|
      serials=[]
      1.upto(3){|i|serials<<k.to_s.gsub(/1yr/, i.to_s+"yr")}
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
    # delete 4 and 5 year durations carried over from high assurance
    ProductVariantItem.where{(serial=~"%evcodesigning256ssl5yr%") | (serial=~"%evcodesigning256ssl4yr%")}.delete_all
  end

  def self.create_email_certs
    Certificate.purge %w(personalbasic personalbusiness personalpro personalenterprise naesbbasic)
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
               price_adjusts:{sslcompersonalpro256ssl1yr: [7000, 8000, 9000],
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
               }},
              {serial_root: "documentsigning",title: "Document Signing",validation_type: "basic",
               summary: "for signing and authenticating documents such as Adobe pdf, Microsoft Office, OpenOffice and LibreOffice",
               product: "document-signing",
               points:  "<div class='check'>Legally binding and complies with the U.S. Federal ESIGN Act</div>
                         <div class='check'>Stored on USB etoken for 2 factor authentication</div>
                         <div class='check'>No required plugins or software</div>
                         <div class='check'>Customizable appearance of digital signature</div>
                         <div class='check'>Shows signed by a person OR department</div>
                         <div class='check'>30 day money-back guarantee </div>
                         <div class='check'>24 hour 5-star support</div>",
               price_adjusts:{sslcomdocumentsigning1yr: [34900,64900,84900],
                              sslcomdocumentsigning1yr1tr: [34900,64900,84900],
                              sslcomdocumentsigning1yr2tr: [12000,15000],
                              sslcomdocumentsigning1yr3tr: [11250,15000],
                              sslcomdocumentsigning1yr4tr: [10500,15000],
                              sslcomdocumentsigning1yr5tr: [9000,15000],
                              sslcomdocumentsigning1yr6tr: [7500,15000],
                              sslcomdocumentsigning1yr7tr: [6000,15000]
               }},
              {serial_root: "naesbbasic",title: "NAESB Basic",validation_type: "basic",
               summary: "for authenticating and encrypting email and well as client services",
               special_fields: %w(entity_code),
               product: "personal-naesb-basic",
               points:  "<div class='check'>Required for NAESB EIR, OASIS and e-Tagging applications</div>
                         <div class='check'>Used for Energy Industry website client authentications</div>
                         <div class='check'>Issued from NAESB ACA SSL.com</div>
                         <div class='check'>2048 bit public key encryption</div>
                         <div class='check'>RSA and ECC supported</div>
                         <div class='check'>Quick issuance</div>
                         <div class='check'>30 day money-back guarantee </div>
                         <div class='check'>24 hour 5-star support</div>",
               price_adjusts:{sslcomnaesbbasicclient1yr: [7500,15000],
                              sslcomnaesbbasicclient1yr1tr: [7500,15000],
                              sslcomnaesbbasicclient1yr2tr: [6000,12000],
                              sslcomnaesbbasicclient1yr3tr: [5625,11250],
                              sslcomnaesbbasicclient1yr4tr: [5025,10500],
                              sslcomnaesbbasicclient1yr5tr: [4500,9000],
                              sslcomnaesbbasicclient1yr6tr: [3750,7500],
                              sslcomnaesbbasicclient1yr7tr: [2625,5250]
               }}]
    products.each do |p|
      c=Certificate.available.find_by_product "high_assurance"
      certs = c.duplicate_w_tiers(product: p, new_serial: "#{p[:serial_root]}256sslcom",
                                old_pvi_serial: "ov256ssl", new_pvi_serial: "#{p[:serial_root]}256ssl")
      title = p[:title]
      description={
          "certificate_type" => title,
          "points" => p[:points] || "",
          "validation_level" => p[:validation_type],
          "summary" => p[:summary],
          "abbr" => title
      }
      certs.each do |c|
        c.update_attributes title: title,
                            description: description,
                            special_fields: p[:special_fields],
                            product: c.product.gsub(/\Ahigh_assurance/, p[:product]),
                            icons: c.icons.merge!("main"=> "gold_lock_lg.gif")
      end
      certs.each{ |c| c.product_variant_items.where{display_order > 3}.destroy_all}
      p[:price_adjusts].each do |k,v|
        serials=[]
        num_years=v.count
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
            pvg.product_variant_items.where{serial << serials}.delete_all
          end
        }
      end
    end
  end

  def self.purge(serial_snippets=[])
    serial_snippets.each do |serial_snippet|
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
      c.cached_product_variant_items.where{value > days}.each{|pvi|pvi.delete}
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
      if c.cached_product_variant_items.where{item_type == "duration"}.count>0 #assume non ucc
        c.cached_product_variant_items.where{item_type == "duration"}.each_with_index{|pvi,i| pvi.update_column :amount, prices[i]}
      elsif c.cached_product_variant_items.where{item_type == "ucc_domain"}.count>0 #assume ucc
        c.cached_product_variant_items.where{item_type == "ucc_domain"}.each{|pvi|
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
