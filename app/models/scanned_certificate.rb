class ScannedCertificate < ApplicationRecord
  has_many :scan_logs
  has_many :notification_groups, through: :scan_logs
  include Concerns::Certificate::X509Properties
end
