class ManagedCsr < Csr
  belongs_to :ssl_account
  has_many :certificate_order_managed_csrs, dependent: :destroy
end
