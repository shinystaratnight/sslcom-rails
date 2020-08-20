class ScanLog < ApplicationRecord
  include Pagable

  belongs_to  :notification_group
  belongs_to  :scanned_certificate
end
