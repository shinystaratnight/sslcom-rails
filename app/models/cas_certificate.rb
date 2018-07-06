class CasCertificate < ActiveRecord::Base
  STATUS = {default: "default",
            active: "active",
            inactive: "inactive",
            shadow: "shadow",
            hide: "hide"}

  belongs_to :ca
  belongs_to :certificate
end



