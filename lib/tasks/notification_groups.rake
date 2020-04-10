namespace 'notification_groups' do
  desc "Set schedule to daily scan for all notification groups"

  task set_schedule_to_daily_scan: :environment do
    NotificationGroup.includes(:schedules).find_in_batches(batch_size: 250) do |batch_list|
      batch_list.each do |group|
        group.set_schedule_to_daily_scan
      end
    end
  end

  desc "Exiting setting schedule"
end
