# == Schema Information
#
# Table name: certificate_order_domains
#
#  id                   :integer          not null, primary key
#  certificate_order_id :integer
#  domain_id            :integer
#

class CertificateOrderDomain < ApplicationRecord
  belongs_to  :certificate_order
  belongs_to  :domain
end
