# == Schema Information
#
# Table name: shopping_carts
#
#  id               :integer          not null, primary key
#  access           :string(255)
#  content          :text(65535)
#  crypted_password :string(255)
#  guid             :string(255)
#  password_salt    :string(255)
#  token            :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :integer
#
# Indexes
#
#  index_shopping_carts_on_guid     (guid)
#  index_shopping_carts_on_user_id  (user_id)
#

# li - number of licenses
# q - quantity
# do - domains
# pr - product code
# rn - renewal order
# du - duration

class ShoppingCart < ApplicationRecord
  belongs_to :user

  LICENSES = "li"
  QUANTITY = "q"
  DOMAINS = "do"
  DURATION = "du"
  PRODUCT_CODE = "pr"
  SUB_PRODUCT_CODE = "spr" # array of sub products that will be added through the sub_order_item
  RENEWAL_ORDER = "rn"
  AFFILIATE = "af"
  DEFAULT_AFFILIATE_ID = 1

  CART_KEY = :cart_102019
  CART_GUID_KEY = :cart_guid_102019
  AID = :aid_102019
  AID_LI = :aid_li_102019
end
