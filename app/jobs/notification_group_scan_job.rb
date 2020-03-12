# frozen_string_literal: true

require 'airbrake/delayed_job'

class NotificationGroupScanJob < Struct.new(:db)
  def perform
    NotificationGroup.scan(db: db)
  end
end
