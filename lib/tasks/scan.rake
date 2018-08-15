namespace 'scan' do
  desc "Scan the domains belongs to notification groups and sending a reminder if expiration date is in reminder days what has been set"
  task scan_and_reminder_expiring_domains: :environment do
    current = DateTime.now
    month = current.strftime("%m").to_i.to_s
    day = current.strftime("%d").to_i.to_s
    week_day = current.strftime("%w")
    hour = current.strftime("%H").to_i.to_s
    minute = current.strftime("%M").to_i.to_s

    NotificationGroup.order('created_at').find_in_batches(batch_size: 250) do |batch_list|
      batch_list.each do |group|
        schedules = {}
        group.schedules.pluck(:schedule_type, :schedule_value).each do |arr|
          if schedules[arr[0]].blank?
            schedules[arr[0]] = arr[1]
          else
            schedules[arr[0]] = (schedules[arr[0]] + '|' + arr[1].to_s).split('|').sort.join('|')
          end
        end

        run_scan = true
        if schedules['Simple']
          if (schedules['Simple'] == '1' && minute != '0') ||
              (schedules['Simple'] == '2' && hour != '0' && minute != '0') ||
              (schedules['Simple'] == '3' && week_day != '0' && hour != '0' && minute != '0') ||
              (schedules['Simple'] == '4' && day != '1' && week_day != '0' && hour != '0' && minute != '0') ||
              (schedules['Simple'] == '5' && month != '1' && day != '1' && week_day != '0' && hour != '0' && minute != '0')
            run_scan = false
          end
        else
          if schedules['Hour']
            run_scan = (schedules['Hour'] == 'All' || schedules['Hour'].split('|').include?(hour))
          else
            run_scan = (hour == '0') unless schedules['Minute']
          end

          if run_scan && schedules['Minute']
            run_scan = (schedules['Minute'] == 'All' || schedules['Minute'].split('|').include?(minute))
          elsif run_scan && !schedules['Minute']
            run_scan = (minute == '0')
          end

          if run_scan
            run_scan_week_day = false
            if schedules['Weekday']
              run_scan_week_day = (schedules['Weekday'] == 'All' || schedules['Weekday'].split('|').include?(week_day))
            end

            unless run_scan_week_day
              if schedules['Month']
                run_scan = (schedules['Month'] == 'All' || schedules['Month'].split('|').include?(month))
              end

              if run_scan && schedules['Day']
                run_scan = (schedules['Day'] == 'All' || schedules['Day'].split('|').include?(day))
              elsif run_scan && !schedules['Day']
                run_scan = (day == '1') unless schedules['Hour'] && schedules['Minute']
              end
            end
          end
        end

        group.scan_notification_group if run_scan
      end
    end
  end
  desc "Exiting scan"
end