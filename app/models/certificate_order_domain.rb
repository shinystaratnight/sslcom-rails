# == Schema Information
#
# Table name: certificate_order_domains
#
#  id                   :integer          not null, primary key
#  certificate_order_id :integer
#  domain_id            :integer
#
# Indexes
#
#  index_certificate_order_domains_on_certificate_order_id  (certificate_order_id)
#  index_certificate_order_domains_on_domain_id             (domain_id)
#

class CertificateOrderDomain < ApplicationRecord
  belongs_to  :certificate_order
  belongs_to  :domain
end
