# == Schema Information
#
# Table name: products
#
#  id                    :integer          not null, primary key
#  amount                :integer
#  auto_renew            :string(255)
#  description           :text(65535)
#  display_order         :string(255)
#  duration              :integer
#  ext_customer_ref      :string(255)
#  icons                 :string(255)
#  notes                 :text(65535)
#  published_as          :string(16)       default("draft")
#  ref                   :string(255)
#  serial                :string(255)
#  status                :string(255)
#  summary               :text(65535)
#  text_only_description :text(65535)
#  text_only_summary     :text(65535)
#  title                 :string(255)
#  type                  :string(255)
#  value                 :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#

# This class represents a template of an item or service that can be sold. See ProductOrder for a purchased
# instance of Product

class Product < ApplicationRecord
  has_many    :product_variant_groups, :as => :variantable
  has_many    :product_variant_items, through: :product_variant_groups
  has_many    :product_orders
  # if this product is to be added to certificate_order as a line_item
  has_many    :sub_order_items, :as => :sub_itemable, :dependent => :destroy
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
  has_and_belongs_to_many :certificates

  def price=(amount)
    self.amount = amount.gsub(/\./,"").to_i
  end

  def api_product_code
    ApiCertificateRequest::PRODUCTS.find{|k,v|
      serial =~ Regexp.new(v)
    }[0].to_s
  end
end
