class CasCertificate < ApplicationRecord
  STATUS = {default: "default",
            active: "active",
            inactive: "inactive",
            shadow: "shadow",
            hide: "hide"}

  GENERAL_DEFAULT_CACHE="general_default_cache"

  belongs_to                    :ca
  belongs_to                    :certificate
  belongs_to                    :ssl_account, touch: true

  scope :ssl_account, ->(ssl_account){where{ssl_account_id==ssl_account.id}.uniq}
  scope :ssl_account_or_general_default, ->(ssl_account){
      (ssl_account(ssl_account).empty? ? general : ssl_account(ssl_account)).default}
  scope :general, ->{where{ssl_account_id==nil}.uniq}
  scope :default, ->{where{status==STATUS[:default]}.uniq}
  scope :shadow,  ->{where{status==STATUS[:shadow]}.uniq}
end



