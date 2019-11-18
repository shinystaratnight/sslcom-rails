namespace 'scan' do
  desc "Scan the domains belongs to notification groups and sending a reminder if expiration date is in reminder days what has been set"
  task scan_and_reminder_expiring_domains: :environment do
    current = DateTime.now
    month = current.strftime("%m").to_i.to_s
    day = current.strftime("%d").to_i.to_s
    week_day = current.strftime("%w")
    hour = current.strftime("%H").to_i.to_s
    minute = current.strftime("%M").to_i.to_s

    groups = []
    group_custom_schedule = {}
    total_schedules = Schedule.order('notification_group_id')
    total_schedules_count = total_schedules.count

    total_schedules.each_with_index do |schedule, idx|
      if schedule.schedule_type == 'Simple'
        if (schedule.schedule_value == '1' && minute != '0') ||
            (schedule.schedule_value == '2' && hour != '0' && minute != '0') ||
            (schedule.schedule_value == '3' && week_day != '0' && hour != '0' && minute != '0') ||
            (schedule.schedule_value == '4' && day != '1' && week_day != '0' && hour != '0' && minute != '0') ||
            (schedule.schedule_value == '5' && month != '1' && day != '1' && week_day != '0' && hour != '0' && minute != '0')
          groups << schedule.notification_group_id
        end
      else
        if group_custom_schedule.empty?
          group_custom_schedule[schedule.notification_group_id] = {}
          group_custom_schedule[schedule.notification_group_id][schedule.schedule_type] = schedule.schedule_value
        else
          group_custom_schedule[schedule.notification_group_id][schedule.schedule_type].blank? ?
              group_custom_schedule[schedule.notification_group_id][schedule.schedule_type] = schedule.schedule_value :
              group_custom_schedule[schedule.notification_group_id][schedule.schedule_type] =
                  (group_custom_schedule[schedule.notification_group_id][schedule.schedule_type] + '|' + schedule.schedule_value).
                      split('|').sort.join('|')
        end
      end

      if !group_custom_schedule.empty? &&
          (((total_schedules_count - 1) == idx) ||
              (((total_schedules_count - 1) > idx) &&
                  (total_schedules[idx + 1].notification_group_id != schedule.notification_group_id)))
        run_scan = true
        note_group_id = group_custom_schedule.keys.first

        if group_custom_schedule[note_group_id]['Hour']
          run_scan = (group_custom_schedule[note_group_id]['Hour'] == 'All' ||
              group_custom_schedule[note_group_id]['Hour'].split('|').include?(hour))
        else
          run_scan = (hour == '0') unless group_custom_schedule[note_group_id]['Minute']
        end

        if run_scan && group_custom_schedule[note_group_id]['Minute']
          run_scan = (group_custom_schedule[note_group_id]['Minute'] == 'All' ||
              group_custom_schedule[note_group_id]['Minute'].split('|').include?(minute))
        elsif run_scan && !group_custom_schedule[note_group_id]['Minute']
          run_scan = (minute == '0')
        end

        if run_scan
          run_scan_week_day = false
          if group_custom_schedule[note_group_id]['Weekday']
            run_scan_week_day = (group_custom_schedule[note_group_id]['Weekday'] == 'All' ||
                group_custom_schedule[note_group_id]['Weekday'].split('|').include?(week_day))
          end

          unless run_scan_week_day
            if group_custom_schedule[note_group_id]['Month']
              run_scan = (group_custom_schedule[note_group_id]['Month'] == 'All' ||
                  group_custom_schedule[note_group_id]['Month'].split('|').include?(month))
            end

            if run_scan && group_custom_schedule[note_group_id]['Day']
              run_scan = (group_custom_schedule[note_group_id]['Day'] == 'All' ||
                  group_custom_schedule[note_group_id]['Day'].split('|').include?(day))
            elsif run_scan && !group_custom_schedule[note_group_id]['Day']
              run_scan = (day == '1') unless group_custom_schedule[note_group_id]['Hour'] &&
                  group_custom_schedule[note_group_id]['Minute']
            end
          end
        end

        groups << note_group_id if run_scan
        group_custom_schedule = {}
      end
    end

    NotificationGroup.where(id: groups)
        .includes(:notification_groups_subjects, :notification_groups_contacts, :schedules)
        .find_in_batches(batch_size: 250) do |batch_list|
      batch_list.each do |group|
        group.scan_notification_group
      end
    end

      # NotificationGroup.order('created_at').find_in_batches(batch_size: 250) do |batch_list|
      #   batch_list.each do |group|
      #     schedules = {}
      #     group.schedules.pluck(:schedule_type, :schedule_value).each do |arr|
      #       if schedules[arr[0]].blank?
      #         schedules[arr[0]] = arr[1]
      #       else
      #         schedules[arr[0]] = (schedules[arr[0]] + '|' + arr[1].to_s).split('|').sort.join('|')
      #       end
      #     end
      #
      #     run_scan = true
      #     if schedules['Simple']
      #       if (schedules['Simple'] == '1' && minute != '0') ||
      #           (schedules['Simple'] == '2' && hour != '0' && minute != '0') ||
      #           (schedules['Simple'] == '3' && week_day != '0' && hour != '0' && minute != '0') ||
      #           (schedules['Simple'] == '4' && day != '1' && week_day != '0' && hour != '0' && minute != '0') ||
      #           (schedules['Simple'] == '5' && month != '1' && day != '1' && week_day != '0' && hour != '0' && minute != '0')
      #         run_scan = false
      #       end
      #     else
      #       if schedules['Hour']
      #         run_scan = (schedules['Hour'] == 'All' || schedules['Hour'].split('|').include?(hour))
      #       else
      #         run_scan = (hour == '0') unless schedules['Minute']
      #       end
      #
      #       if run_scan && schedules['Minute']
      #         run_scan = (schedules['Minute'] == 'All' || schedules['Minute'].split('|').include?(minute))
      #       elsif run_scan && !schedules['Minute']
      #         run_scan = (minute == '0')
      #       end
      #
      #       if run_scan
      #         run_scan_week_day = false
      #         if schedules['Weekday']
      #           run_scan_week_day = (schedules['Weekday'] == 'All' || schedules['Weekday'].split('|').include?(week_day))
      #         end
      #
      #         unless run_scan_week_day
      #           if schedules['Month']
      #             run_scan = (schedules['Month'] == 'All' || schedules['Month'].split('|').include?(month))
      #           end
      #
      #           if run_scan && schedules['Day']
      #             run_scan = (schedules['Day'] == 'All' || schedules['Day'].split('|').include?(day))
      #           elsif run_scan && !schedules['Day']
      #             run_scan = (day == '1') unless schedules['Hour'] && schedules['Minute']
      #           end
      #         end
      #       end
      #     end
      #
      #     group.scan_notification_group if run_scan
      #   end
      # end
  end
  desc "Exiting scan"
end