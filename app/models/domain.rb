class Domain < CertificateName
  belongs_to  :ssl_account, touch: true
  has_many  :certificate_order_domains, dependent: :destroy

  #will_paginate
  cattr_accessor :per_page
  @@per_page = 10

  cattr_accessor :csr_per_page
  @@csr_per_page = 10
end
