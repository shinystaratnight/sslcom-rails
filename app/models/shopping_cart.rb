#li - number of licenses
#q - quantity
#do - domains
#pr - product code
#rn - renewal order
#du - duration
class ShoppingCart < ActiveRecord::Base
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

  CART_KEY = :cart
  CART_GUID_KEY = :cart_guid
end
