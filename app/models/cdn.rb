class Cdn < ApplicationRecord
  belongs_to :ssl_account
  belongs_to :certificate_order

  #will_paginate
  cattr_accessor :per_page
  @@per_page = 10
end
