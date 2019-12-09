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
