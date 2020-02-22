# == Schema Information
#
# Table name: certificate_order_managed_csrs
#
#  id                   :integer          not null, primary key
#  created_at           :datetime
#  updated_at           :datetime
#  certificate_order_id :integer
#  managed_csr_id       :integer
#
# Indexes
#
#  index_certificate_order_managed_csrs_on_certificate_order_id  (certificate_order_id)
#  index_certificate_order_managed_csrs_on_managed_csr_id        (managed_csr_id)
#

class CertificateOrderManagedCsr < ApplicationRecord
  belongs_to  :certificate_order
  belongs_to  :managed_csr
end
