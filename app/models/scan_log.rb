# == Schema Information
#
# Table name: scan_logs
#
#  id                     :integer          not null, primary key
#  domain_name            :string(255)
#  expiration_date        :datetime
#  scan_group             :integer
#  scan_status            :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  notification_group_id  :integer
#  scanned_certificate_id :integer
#
# Indexes
#
#  index_scan_logs_on_notification_group_id   (notification_group_id)
#  index_scan_logs_on_scanned_certificate_id  (scanned_certificate_id)
#

class ScanLog < ApplicationRecord
  include Pagable

  belongs_to  :notification_group
  belongs_to  :scanned_certificate
end
