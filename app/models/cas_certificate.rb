# == Schema Information
#
# Table name: cas_certificates
#
#  id             :integer          not null, primary key
#  status         :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  ca_id          :integer          not null
#  certificate_id :integer          not null
#  ssl_account_id :integer
#
# Indexes
#
#  index_cas_certificates_on_ca_id                     (ca_id)
#  index_cas_certificates_on_certificate_id            (certificate_id)
#  index_cas_certificates_on_certificate_id_and_ca_id  (certificate_id,ca_id)
#  index_cas_certificates_on_ssl_account_id            (ssl_account_id)
#

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



