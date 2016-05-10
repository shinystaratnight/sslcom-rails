class ProductVariantItem < ActiveRecord::Base
  acts_as_sellable :cents => :amount, :currency => false
  belongs_to  :product_variant_group
  has_one :sub_order_item
  acts_as_publishable :live, :draft, :discontinue_sell

  #validates_uniqueness_of :display_order, :scope => :product_variant_group_id
  validates_presence_of :product_variant_group

  def certificate
    product_variant_group.variantable if
      product_variant_group &&
      product_variant_group.variantable &&
      product_variant_group.variantable.is_a?(Certificate)
  end

  def is_domain?
    item_type=='ucc_domain'
  end

  def is_duration?
    item_type=='duration'
  end

  def is_server_license?
    item_type=='server_license'
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
end
