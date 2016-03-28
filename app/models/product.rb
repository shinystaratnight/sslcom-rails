# This class represents a template of an item or service that can be sold. See ProductOrder for a purchased
# instance of Product

class Product < ActiveRecord::Base
  has_many    :product_variant_groups, :as => :variantable
  has_many    :product_variant_items, through: :product_variant_groups
  has_many    :product_orders
  acts_as_publishable :live, :draft, :discontinue_sell
  # belongs_to  :reseller_tier
  serialize   :icons
  serialize   :description
  serialize   :display_order
  serialize   :title
  has_and_belongs_to_many :parent_products, class_name: 'Product', association_foreign_key:
      :sub_product_id, join_table: 'products_sub_products'
  has_and_belongs_to_many :sub_products, class_name: 'Product', foreign_key:
      :sub_product_id, join_table: 'products_sub_products'

  def price=(amount)
    self.amount = amount.gsub(/\./,"").to_i
  end

  def api_product_code
    ApiCertificateCreate_v1_4::PRODUCTS.find{|k,v|
      serial =~ Regexp.new(v)
    }[0].to_s
  end
end