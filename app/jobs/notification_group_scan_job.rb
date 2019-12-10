# frozen_string_literal: true

# app/jobs/notification_group_scan_job.rb
# rubocop:disable Style/StructInheritance
class NotificationGroupScanJob < Struct.new(:db)
  queue_as :default

  def perform
    NotificationGroup.scan(db: db)
  end
end
# rubocop:enable Style/StructInheritance
