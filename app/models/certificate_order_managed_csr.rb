class CertificateOrderManagedCsr < ActiveRecord::Base
  belongs_to  :certificate_order
  belongs_to  :managed_csr
end
