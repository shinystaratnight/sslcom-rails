class ScanLog < ActiveRecord::Base
  belongs_to  :notification_group
  belongs_to  :scanned_certificate
end