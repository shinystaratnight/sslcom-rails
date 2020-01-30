# frozen_string_literal: true

class ScanLog < ApplicationRecord
  belongs_to  :notification_group
  belongs_to  :scanned_certificate
end
