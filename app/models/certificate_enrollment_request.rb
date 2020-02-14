# == Schema Information
#
# Table name: certificate_enrollment_requests
#
#  id                 :integer          not null, primary key
#  common_name        :text(65535)
#  domains            :text(65535)      not null
#  duration           :integer          not null
#  signing_request    :text(65535)
#  status             :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  certificate_id     :integer          not null
#  order_id           :integer
#  server_software_id :integer
#  ssl_account_id     :integer          not null
#  user_id            :integer
#
# Indexes
#
#  index_certificate_enrollment_requests_on_certificate_id  (certificate_id)
#  index_certificate_enrollment_requests_on_order_id        (order_id)
#  index_certificate_enrollment_requests_on_ssl_account_id  (ssl_account_id)
#  index_certificate_enrollment_requests_on_user_id         (user_id)
#

class CertificateEnrollmentRequest < ApplicationRecord
  include Filterable
  include Sortable

  attr_accessor :additional_domains, :ssl_slug

  enum status: { pending: 1, approved: 5, rejected: 10 }

  belongs_to :ssl_account
  belongs_to :user
  belongs_to :certificate
  belongs_to :order

  serialize :domains

  validates :ssl_account, presence: true

  def self.index_filter(params)
    filters = {}
    p = params
    filters[:id] = { '=' => p[:id] } unless p[:id].blank?
    result = filter(filters)
    result
  end
end
