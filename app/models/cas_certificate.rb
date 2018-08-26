class CasCertificate < ActiveRecord::Base
  STATUS = {default: "default",
            active: "active",
            inactive: "inactive",
            shadow: "shadow",
            hide: "hide"}

  belongs_to                    :ca
  belongs_to                    :certificate
  has_and_belongs_to_many :ssl_accounts
end



