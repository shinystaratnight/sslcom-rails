class ManagedCertificate < SignedCertificate
  # will_paginate
  cattr_accessor :per_page
  @@per_page = 10
end