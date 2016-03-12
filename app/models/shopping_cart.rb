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
  RENEWAL_ORDER = "rn"
  AFFILIATE = "af"
  DEFAULT_AFFILIATE_ID = 1
end
