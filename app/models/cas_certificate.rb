class CasCertificate < ActiveRecord::Base
  STATUS = {default: "default",
            active: "active",
            inactive: "inactive",
            shadow: "shadow",
            hide: "hide"}

  belongs_to                    :ca
  belongs_to                    :certificate
  belongs_to                    :ssl_account

  scope :ssl_account, ->(ssl_account){where{ssl_account_id==ssl_account.id}}
  scope :ssl_account_or_general_default, ->(ssl_account){
      (ssl_account(ssl_account).empty? ? general : ssl_account(ssl_account)).default}
  scope :general, ->{where{ssl_account_id==nil}}
  scope :default, ->{where{status==STATUS[:default]}}
  scope :shadow,  ->{where{status==STATUS[:shadow]}}
end



