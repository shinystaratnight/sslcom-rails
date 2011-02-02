#represents an interface to storing cart data. We the data being stored in a
#cookie or the db should be independent from the code
#li - number of licenses
#q - quantity
#do - domains
#pr - product code
#rn - renewal order
#du - duration
module ShoppingCart
  LICENSES = "li"
  QUANTITY = "q"
  DOMAINS = "do"
  DURATION = "du"
  PRODUCT_CODE = "pr"
  RENEWAL_ORDER = "rn"
  AFFILIATE = "af"
  DEFAULT_AFFILIATE_ID = 1
end
