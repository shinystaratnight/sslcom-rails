class CertificateLookup < ActiveRecord::Base
  has_many :site_checks
end
