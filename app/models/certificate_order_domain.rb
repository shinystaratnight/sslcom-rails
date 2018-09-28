class CertificateOrderDomain < ActiveRecord::Base
  belongs_to  :certificate_order
  belongs_to  :domain
end
