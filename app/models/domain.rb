class Domain < CertificateName
  include Pagable

  belongs_to :ssl_account, touch: true
  has_many :certificate_order_domains, dependent: :destroy
end
