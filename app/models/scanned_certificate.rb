# == Schema Information
#
# Table name: scanned_certificates
#
#  id         :integer          not null, primary key
#  body       :text(65535)
#  decoded    :text(65535)
#  serial     :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class ScannedCertificate < ApplicationRecord
  has_many :scan_logs
  has_many :notification_groups, through: :scan_logs
  include Concerns::Certificate::X509Properties
end
