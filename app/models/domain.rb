class Domain < CertificateName
  belongs_to  :ssl_account
  has_many  :certificate_order_domains, dependent: :destroy
end
