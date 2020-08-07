class CertificateOrderDomain < ApplicationRecord
  belongs_to  :certificate_order
  belongs_to  :domain
end
