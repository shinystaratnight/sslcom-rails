class ScanLog < ActiveRecord::Base
  belongs_to  :notification_group
  belongs_to  :scanned_certificate

  # will_paginate
  cattr_accessor :per_page
  @@per_page = 10
end