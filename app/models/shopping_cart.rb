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
