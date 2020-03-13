class NotificationGroupsController < ApplicationController
  before_action :require_user, only: [:index, :new, :create, :edit, :update, :destroy]
  before_action :find_notification_group, only: :scan_individual_group
  before_action :find_ssl_account
  before_filter :global_set_row_page, only: [:index, :search]
  before_action :set_schedule_value, only: [:index, :new, :edit, :search]

  def search
    @filter_slt_type = params[:filter_type]

    if params[:filter_type] == 'true'
      @notification_groups = @ssl_account.notification_groups.paginate(@p)
    else
      @filter_slt_schedule_type = params[:filter_schedule_type]

      if params[:filter_schedule_type] == 'true'
        @filter_slt_schedule_simple = params[:filter_schedule_simple]
        notification_group_ids = Schedule.where(schedule_type: 'Simple',
                                                schedule_value: params[:filter_schedule_simple])
                                     .pluck(:notification_group_id).uniq
        @notification_groups = @ssl_account.notification_groups.where(id: notification_group_ids).paginate(@p)
      else
        notification_group_ids = []

        if params[:filter_weekday_type] == 'true'
          notification_group_ids.concat Schedule.
              where(schedule_type: 'Weekday',
                    schedule_value: 'All').
              pluck(:notification_group_id).uniq
        else
          @filter_slt_weekdays = params[:filter_weekday]
          notification_group_ids.concat Schedule.
              where(schedule_type: 'Weekday',
                    schedule_value: params[:filter_weekday]).
              pluck(:notification_group_id).uniq
        end

        if params[:filter_month_type] == 'true'
          notification_group_ids.concat Schedule.
              where(schedule_type: 'Month',
                    schedule_value: 'All').
              pluck(:notification_group_id).uniq
        else
          @filter_slt_months = params[:filter_month]
          notification_group_ids.concat Schedule.
              where(schedule_type: 'Month',
                    schedule_value: params[:filter_month]).
              pluck(:notification_group_id).uniq
        end

        if params[:filter_day_type] == 'true'
          notification_group_ids.concat Schedule.
              where(schedule_type: 'Day',
                    schedule_value: 'All').
              pluck(:notification_group_id).uniq
        else
          @filter_slt_days = params[:filter_day]
          notification_group_ids.concat Schedule.
              where(schedule_type: 'Day',
                    schedule_value: params[:filter_day]).
              pluck(:notification_group_id).uniq
        end

        if params[:filter_hour_type] == 'true'
          notification_group_ids.concat Schedule.
              where(schedule_type: 'Hour',
                    schedule_value: 'All').
              pluck(:notification_group_id).uniq
        else
          @filter_slt_hours = params[:filter_hour]
          notification_group_ids.concat Schedule.
              where(schedule_type: 'Hour',
                    schedule_value: params[:filter_hour]).
              pluck(:notification_group_id).uniq
        end

        if params[:filter_minute_type] == 'true'
          notification_group_ids.concat Schedule.
              where(schedule_type: 'Minute',
                    schedule_value: 'All').
              pluck(:notification_group_id).uniq
        else
          @filter_slt_minutes = params[:filter_minute]
          notification_group_ids.concat Schedule.
              where(schedule_type: 'Minute',
                    schedule_value: params[:filter_minute]).
              pluck(:notification_group_id).uniq
        end

        @notification_groups = @ssl_account.notification_groups.where(id: notification_group_ids.uniq).paginate(@p)
      end
    end

    respond_to do |format|
      format.html { render :action => :index }
      format.xml  { render :xml => @notification_groups }
    end
  end

  def index
    @notification_groups = @ssl_account.notification_groups.paginate(@p)
  end

  def remove_groups
    group_ids = params[:note_group_check]
    Preference.where(owner_type: 'NotificationGroup', owner_id: group_ids).destroy_all
    NotificationGroup.where(id: group_ids).destroy_all

    flash[:notice] = "Selected notification groups has been removed successfully."
    redirect_to notification_groups_path(ssl_slug: @ssl_slug)
  end

  def scan_groups
    notificaton_group_ids = params[:note_group_check]
    notification_groups = NotificationGroup.where(id: notificaton_group_ids, status: false).includes(:certificate_names, :notification_groups_subjects, :notification_groups_contacts)

    notification_groups.map do |ng|
      ng.scan
    end

    flash[:notice] = "Scan has been done successfully for only enabled Notification Groups. Delivering email receipt."
    redirect_to notification_groups_path(ssl_slug: @ssl_slug)
  end

  def change_status_groups
    group_ids = params[:note_group_check]
    note_group_status = params[:note_groups_status]

    @ssl_account.notification_groups.where(id: group_ids).update_all(status: note_group_status == 'true')

    flash[:notice] = "It has been updated status to " + note_group_status == 'true' ? 'Enable' : 'Disable' + " successfully."
    redirect_to notification_groups_path(ssl_slug: @ssl_slug)
  end

  def scan_individual_group
    @notification_group.scan

    flash[:notice] = "Scan has been done successfully. Delivering email receipt."
    redirect_to notification_group_scan_logs_url(@ssl_slug, @notification_group.id)
  end

  def new
    certificate_names = @ssl_account.cached_certificate_names.pluck(:name, :id)
    @subjects_list = remove_duplicate(certificate_names)
                         .map{ |arr| [arr[0], arr[0] + '---' + arr[1].to_s] }
    @contacts_list = remove_duplicate(@ssl_account.certificate_orders.includes({certificate_contents: :certificate_contacts}).flatten.compact
                                          .map(&:certificate_contents).flatten.compact
                                          .map(&:certificate_contacts).flatten.compact.map{ |cct| [cct.email, cct.id] })
                         .map{ |arr| [arr[0], arr[0] + '---' + arr[1].to_s] }
    @cos_list = @ssl_account.certificate_orders.pluck(:ref, :id).uniq
    @title = 'New SSL Expiration Notification Group'

    render 'group'
  end

  def edit
    @notification_group = @ssl_account.notification_groups
                              .includes(:notification_groups_subjects, :notification_groups_contacts, :schedules)
                              .where(id: params[:id]).first

    slt_cert_orders = @notification_group.certificate_orders.flatten.compact
    @cos_list = @ssl_account.certificate_orders.pluck(:ref, :id).uniq
    @slt_cos_list = slt_cert_orders.map(&:id)

    @slt_subjects_list = generate_slt_subjects
    domain_names = @notification_group.notification_groups_subjects.where(subjectable_id: nil)
    @subjects_list = remove_duplicate(@ssl_account.certificate_names.pluck(:name, :id))
                         .map{ |arr| [arr[0], @slt_subjects_list.include?(arr[1].to_s) ? arr[1] : (arr[0] + '---' + arr[1].to_s)] }
                         .concat(domain_names.pluck(:domain_name, :domain_name))

    @slt_contacts_list = generate_slt_contacts
    email_addresses = @notification_group.notification_groups_contacts.where(contactable_id: nil)
    @contacts_list = remove_duplicate(
        @ssl_account.certificate_orders.includes({certificate_contents: :certificate_contacts}).flatten.compact
            .map(&:certificate_contents).flatten.compact
            .map(&:certificate_contacts).flatten.compact
            .map{ |cct| [cct.email, cct.id] }
    ).map{ |arr| [arr[0], @slt_contacts_list.include?(arr[1].to_s) ? arr[1] : (arr[0] + '---' + arr[1].to_s)] }
                         .concat(email_addresses.pluck(:email_address, :email_address))

    @slt_schedule_simple = @notification_group.schedules.where(schedule_type: 'Simple').
        pluck(:schedule_value)
    @slt_schedule_weekdays = @notification_group.schedules.where(schedule_type: 'Weekday').
        pluck(:schedule_value)
    @slt_schedule_months = @notification_group.schedules.where(schedule_type: 'Month').
        pluck(:schedule_value)
    @slt_schedule_days = @notification_group.schedules.where(schedule_type: 'Day').
        pluck(:schedule_value)
    @slt_schedule_hours = @notification_group.schedules.where(schedule_type: 'Hour').
        pluck(:schedule_value)
    @slt_schedule_minutes = @notification_group.schedules.where(schedule_type: 'Minute').
        pluck(:schedule_value)

    @title = 'Edit SSL Expiration Notification Group'

    render 'group'
  end

  def check_duplicate
    returnObj = {}
    if params[:friendly_name].blank?
      returnObj['is_duplicated'] = 'false'
    else
      notification_group = @ssl_account.notification_groups.find_by_friendly_name(params[:friendly_name])
      returnObj['is_duplicated'] = notification_group ?
                                       (params[:ng_id] == '' ?
                                            'true' :
                                            (notification_group.id.to_s == params[:ng_id] ?
                                                 'false' : 'true'))
                                       : 'false'
    end

    render :json => returnObj
  end

  def register_notification_group
    if params[:format]
      # Saving notification group info
      # notification_group = @ssl_account.cached_notification_groups.includes(:notification_groups_subjects).where(ref: params[:format]).first
      notification_group = @ssl_account.notification_groups
                               .includes(:notification_groups_subjects, :notification_groups_contacts, :schedules)
                               .where(ref: params[:format]).first
      notification_group.friendly_name = params[:friendly_name] unless params[:friendly_name].blank?
      notification_group.scan_port = params[:scan_port]
      notification_group.notify_all = params[:notify_all] ? params[:notify_all] : false
      notification_group.status = params[:status] ? params[:status] : false
    else
      # Saving notification group info
      notification_group = NotificationGroup.new(
          friendly_name: params[:friendly_name],
          scan_port: params[:scan_port],
          notify_all: params[:notify_all] ? params[:notify_all] : false,
          ssl_account: @ssl_account,
          status: params[:status] ? params[:status] : false
      )
    end

    # Saving notification group triggers
    if params[:notification_group_triggers]
      params[:notification_group_triggers].uniq.sort{|a,b|a.to_i <=> b.to_i}.reverse.each_with_index do |rt, i|
        notification_group.preferred_notification_group_triggers = rt.or_else(nil), ReminderTrigger.find(i+1)
      end
    end

    unless notification_group.save
      flash[:error] = "Some error occurs while saving notification group data. Please try again."

      redirect_to new_notification_group_path(ssl_slug: @ssl_slug) and return unless params[:format]
      redirect_to edit_notification_group_path(@ssl_slug, notification_group.id) and return
    end

    # Saving certificate order tags
    if params[:cos_list]
      current_tags = notification_group.certificate_orders.pluck(:id).map(&:to_s)
      remove_tags = current_tags - params[:cos_list]
      add_tags = params[:cos_list] - current_tags

      # Remove old tags
      notification_group.notification_groups_subjects.
          where(subjectable_type: 'CertificateOrder', subjectable_id: remove_tags).destroy_all

      # Add new tags
      add_tags.each do |id|
        notification_group.notification_groups_subjects.build(
            subjectable_type: 'CertificateOrder', subjectable_id: id
        ).save
      end
    else
      notification_group.notification_groups_subjects
          .where(subjectable_type: 'CertificateOrder').destroy_all
    end

    # Saving subject tags
    if params[:subjects_list]
      parsed_params = parse_params(params[:subjects_list])
      current_tags = notification_group.notification_groups_subjects
                         .where(subjectable_type: ['CertificateName', nil]).pluck(:domain_name, :subjectable_id)
                         .map{ |arr| arr[0].blank? ? arr[1].to_s : (arr[1].blank? ? arr[0] : (arr[0] + '---' + arr[1].to_s)) }
      remove_tags = current_tags - parsed_params
      add_tags = parsed_params - current_tags

      # Remove old tags
      remove_tags.each do |subject|
        if subject.split('---').size == 1
          if subject !~ /\D/
            notification_group.notification_groups_subjects
                .where(subjectable_type: 'CertificateName', subjectable_id: subject).destroy_all
          else
            notification_group.notification_groups_subjects.where(domain_name: subject).destroy_all
          end
        else
          notification_group.notification_groups_subjects
              .where(subjectable_type: 'CertificateName', subjectable_id: subject.split('---')[1]).destroy_all
        end
      end

      # Add new tags
      add_tags.each do |subject|
        if subject.split('---').size == 1
          if subject !~ /\D/
            notification_group.notification_groups_subjects.build(
                subjectable_type: 'CertificateName', subjectable_id: subject
            ).save
          else
            notification_group.notification_groups_subjects.build(
                domain_name: subject
            ).save
          end
        else
          notification_group.notification_groups_subjects.build(
              domain_name: subject.split('---')[0],
              subjectable_id: subject.split('---')[1],
              subjectable_type: 'CertificateName'
          ).save
        end
      end
    else
      # Remove all domains for this notification group
      notification_group.notification_groups_subjects.where(subjectable_type: ['CertificateName', nil]).destroy_all
    end

    # Saving contact tags
    if params[:contacts_list]
      parsed_params = parse_params(params[:contacts_list])
      current_tags = notification_group.notification_groups_contacts.pluck(:email_address, :contactable_id)
                         .map{ |arr| arr[0].blank? ? arr[1].to_s : (arr[1].blank? ? arr[0] : (arr[0] + '---' + arr[1].to_s)) }
      remove_tags = current_tags - parsed_params
      add_tags = parsed_params - current_tags

      # Remove old tags
      remove_tags.each do |contact|
        if contact.split('---').size == 1
          if contact !~ /\D/
            notification_group.notification_groups_contacts
                .where(contactable_type: 'CertificateContact', contactable_id: contact).destroy_all
          else
            notification_group.notification_groups_contacts.where(email_address: contact).destroy_all
          end
        else
          notification_group.notification_groups_contacts
              .where(contactable_type: 'CertificateContact', contactable_id: contact.split('---')[1]).destroy_all
        end
      end

      # Add new tags
      add_tags.each do |contact|
        if contact.split('---').size == 1
          if contact !~ /\D/
            notification_group.notification_groups_contacts.build(
                contactable_type: 'CertificateContact', contactable_id: contact
            ).save
          else
            notification_group.notification_groups_contacts.build(
                email_address: contact
            ).save
          end
        else
          notification_group.notification_groups_contacts.build(
              email_address: contact.split('---')[0],
              contactable_id: contact.split('---')[1],
              contactable_type: 'CertificateContact'
          ).save
        end
      end
    else
      # Remove all domains for this notification group
      notification_group.notification_groups_contacts.destroy_all
    end

    # Saving schedule
    if params[:schedule_type] == 'true'
      current_schedules = notification_group.schedules.pluck(:schedule_type)
      if current_schedules.include? 'Simple'
        notification_group.schedules.last.update_attribute(:schedule_value, params[:schedule_simple_type])
      else
        notification_group.schedules.destroy_all
        notification_group.schedules.build(
            schedule_type: 'Simple',
            schedule_value: params[:schedule_simple_type]
        ).save
      end
    else
      current_schedules = notification_group.schedules.pluck(:schedule_type)
      if current_schedules.include? 'Simple'
        notification_group.schedules.destroy_all
      end

      # Weekday
      current_schedules = notification_group.schedules.where(schedule_type: 'Weekday').pluck(:schedule_value)
      if params[:weekday_type] == 'true'
        unless current_schedules.include? 'All'
          notification_group.schedules.where(schedule_type: 'Weekday').destroy_all
          notification_group.schedules.build(
              schedule_type: 'Weekday',
              schedule_value: 'All'
          ).save
        end
      else
        params[:weekday_custom_list] ||= []
        new_weekdays = params[:weekday_custom_list] - current_schedules
        old_weekdays = current_schedules - params[:weekday_custom_list]

        notification_group.schedules.where(schedule_type: 'Weekday', schedule_value: old_weekdays).destroy_all
        new_weekdays.each do |weekday|
          notification_group.schedules.build(
              schedule_type: 'Weekday',
              schedule_value: weekday
          ).save
        end
      end

      # Month
      current_schedules = notification_group.schedules.where(schedule_type: 'Month').pluck(:schedule_value)
      if params[:month_type] == 'true'
        unless current_schedules.include? 'All'
          notification_group.schedules.where(schedule_type: 'Month').destroy_all
          notification_group.schedules.build(
              schedule_type: 'Month',
              schedule_value: 'All'
          ).save
        end
      else
        params[:month_custom_list] ||= []
        new_months = params[:month_custom_list] - current_schedules
        old_months = current_schedules - params[:month_custom_list]

        notification_group.schedules.where(schedule_type: 'Month', schedule_value: old_months).destroy_all
        new_months.each do |month|
          notification_group.schedules.build(
              schedule_type: 'Month',
              schedule_value: month
          ).save
        end
      end

      # Day
      current_schedules = notification_group.schedules.where(schedule_type: 'Day').pluck(:schedule_value)
      if params[:day_type] == 'true'
        unless current_schedules.include? 'All'
          notification_group.schedules.where(schedule_type: 'Day').destroy_all
          notification_group.schedules.build(
              schedule_type: 'Day',
              schedule_value: 'All'
          ).save
        end
      else
        params[:day_custom_list] ||= []
        new_days = params[:day_custom_list] - current_schedules
        old_days = current_schedules - params[:day_custom_list]

        notification_group.schedules.where(schedule_type: 'Day', schedule_value: old_days).destroy_all
        new_days.each do |day|
          notification_group.schedules.build(
              schedule_type: 'Day',
              schedule_value: day
          ).save
        end
      end

      # Hour
      current_schedules = notification_group.schedules.where(schedule_type: 'Hour').pluck(:schedule_value)
      if params[:hour_type] == 'true'
        unless current_schedules.include? 'All'
          notification_group.schedules.where(schedule_type: 'Hour').destroy_all
          notification_group.schedules.build(
              schedule_type: 'Hour',
              schedule_value: 'All'
          ).save
        end
      else
        params[:hour_custom_list] ||= []
        new_hours = params[:hour_custom_list] - current_schedules
        old_hours = current_schedules - params[:hour_custom_list]

        notification_group.schedules.where(schedule_type: 'Hour', schedule_value: old_hours).destroy_all
        new_hours.each do |hour|
          notification_group.schedules.build(
              schedule_type: 'Hour',
              schedule_value: hour
          ).save
        end
      end

      # Minute
      current_schedules = notification_group.schedules.where(schedule_type: 'Minute').pluck(:schedule_value)
      if params[:minute_type] == 'true'
        unless current_schedules.include? 'All'
          notification_group.schedules.where(schedule_type: 'Minute').destroy_all
          notification_group.schedules.build(
              schedule_type: 'Minute',
              schedule_value: 'All'
          ).save
        end
      else
        params[:minute_custom_list] ||= []
        new_minutes = params[:minute_custom_list] - current_schedules
        old_minutes = current_schedules - params[:minute_custom_list]

        notification_group.schedules.where(schedule_type: 'Minute', schedule_value: old_minutes).destroy_all
        new_minutes.each do |minute|
          notification_group.schedules.build(
              schedule_type: 'Minute',
              schedule_value: minute
          ).save
        end
      end
    end

    flash[:notice] = "Notification group has been updated successfully."
    flash[:notice] = "New notification group has been created successfully." unless params[:format]

    redirect_to notification_groups_path(ssl_slug: @ssl_slug) and return
  end

  def certificate_orders_domains_contacts
    domains = []
    domain_ids = []
    contacts = []
    contact_ids = []

    if params['cos'] && params['cos'].size > 0
      certificate_contents = @ssl_account.certificate_orders
                                 .includes({certificate_contents: [:certificate_names, :certificate_contacts]})
                                 .where(id: params['cos']).flatten.compact
                                 .map(&:certificate_contents).flatten.compact

      removed_dup_cns = remove_duplicate(certificate_contents.map(&:certificate_names)
                                             .flatten.compact.map{ |cn| [cn.name, cn.id] })
      domains.concat removed_dup_cns.keys
      domain_ids.concat removed_dup_cns.values

      removed_dup_ccts = remove_duplicate(certificate_contents.map(&:certificate_contacts)
                                              .flatten.compact.map{ |cct| [cct.email, cct.id] })
      contacts.concat removed_dup_ccts.keys
      contact_ids.concat removed_dup_ccts.values
    end

    results = {}
    results['domains'] = domains
    results['domain_ids'] = domain_ids
    results['contacts'] = contacts
    results['contact_ids'] = contact_ids

    render :json => results
  end

  private

  def find_notification_group
    @notification_group = NotificationGroup.includes(:certificate_names, :notification_groups_subjects, :notification_groups_contacts).find_by_id(params[:notification_group_id])
  end

  def remove_duplicate(mArry)
    result = {}

    mArry.each do |arr|
      if result[arr[0]].blank?
        result[arr[0]] = arr[1].to_s
      else
        result[arr[0]] = (result[arr[0]] + '|' + arr[1].to_s).split('|').sort.join('|')
      end
    end

    result
  end

  def parse_params(params)
    result = []

    params.each do |param|
      if param !~ /\D/
        result << param
      else
        if param.split('---').size == 1
          param.split('|').size == 1 ? result << param : result.concat(param.split('|'))
        else
          if param.split('---')[1].split('|').size == 1
            result << param
          else
            result.concat(param.split('---')[1].split('|').map{ |val| param.split('---')[0] + '---' + val })
          end
        end
      end
    end

    result
  end

  def generate_slt_subjects
    result = []

    subjects = @notification_group.notification_groups_subjects
    typed_subjects = subjects.where(["domain_name IS NOT ? and subjectable_id IS ?",
                                     nil,
                                     nil]).pluck(:domain_name)
    result.concat(typed_subjects)

    selected_subjects = remove_duplicate(
        subjects.where.not(domain_name: nil, subjectable_id: nil).pluck(:domain_name, :subjectable_id)
    ).map{ |arr| arr[0] + '---' + arr[1].to_s }
    result.concat(selected_subjects)

    from_cert_orders = remove_duplicate(
        @ssl_account.cached_certificate_names
            .where(id: subjects.where(domain_name: nil, subjectable_type: 'CertificateName')
                           .pluck(:subjectable_id))
            .pluck(:name, :id)
    ).map{ |arr| arr[1].to_s }

    result.concat(from_cert_orders)

    result
  end

  def generate_slt_contacts
    result = []

    contacts = @notification_group.notification_groups_contacts
    typed_contacts = contacts.where(["email_address IS NOT ? and contactable_id IS ?",
                                     nil,
                                     nil]).pluck(:email_address)
    result.concat(typed_contacts)

    selected_contacts = remove_duplicate(
        contacts.where.not(email_address: nil, contactable_id: nil).pluck(:email_address, :contactable_id)
    ).map{ |arr| arr[0] + '---' + arr[1].to_s }
    result.concat(selected_contacts)

    slt_contact_ids = contacts.where(email_address: nil, contactable_type: 'CertificateContact').pluck(:contactable_id)

    from_cert_orders = remove_duplicate(
        @ssl_account.certificate_orders.includes({certificate_contents: :certificate_contacts}).flatten.compact
            .map(&:certificate_contents).flatten.compact
            .map(&:certificate_contacts).flatten.compact
            .select{ |contact| slt_contact_ids.include?(contact.id) }
            .map{ |contact| [contact.email, contact.id.to_s] }
    ).map{ |arr| arr[1] }

    result.concat(from_cert_orders)

    result
  end

  def set_schedule_value
    @schedule_simple_type = [
        ['Hourly', '1'],
        ['Daily (at midnight)', '2'],
        ['Weekly (on Sunday)', '3'],
        ['Monthly (on the 1st)', '4'],
        ['Yearly (on 1st Jan)', '5']
    ]

    @schedule_weekdays = [
        ['Sunday', '0'], ['Monday', '1'], ['Tuesday', '2'], ['Wednesday', '3'],
        ['Thursday', '4'], ['Friday', '5'], ['Saturday', '6']
    ]

    @schedule_months = [
        ['January', '1'], ['Febrary', '2'], ['March', '3'], ['April', '4'], ['May', '5'], ['June', '6'],
        ['July', '7'], ['August', '8'], ['September', '9'], ['October', '10'], ['November', '11'], ['December', '12']
    ]

    @schedule_days = [
        ['1', '1'], ['2', '2'], ['3', '3'], ['4', '4'], ['5', '5'], ['6', '6'],
        ['7', '7'], ['8', '8'], ['9', '9'], ['10', '10'], ['11', '11'], ['12', '12'],
        ['13', '13'], ['14', '14'], ['15', '15'], ['16', '16'], ['17', '17'], ['18', '18'],
        ['19', '19'], ['20', '20'], ['21', '21'], ['22', '22'], ['23', '23'], ['24', '24'],
        ['25', '25'], ['26', '26'], ['27', '27'], ['28', '28'], ['29', '29'], ['30', '30'], ['31', '31']
    ]

    @schedule_hours = [
        ['0', '0'], ['1', '1'], ['2', '2'], ['3', '3'], ['4', '4'], ['5', '5'], ['6', '6'],
        ['7', '7'], ['8', '8'], ['9', '9'], ['10', '10'], ['11', '11'], ['12', '12'],
        ['13', '13'], ['14', '14'], ['15', '15'], ['16', '16'], ['17', '17'], ['18', '18'],
        ['19', '19'], ['20', '20'], ['21', '21'], ['22', '22'], ['23', '23']
    ]

    @schedule_minutes = [
        ['0', '0'], ['1', '1'], ['2', '2'], ['3', '3'], ['4', '4'], ['5', '5'], ['6', '6'],
        ['7', '7'], ['8', '8'], ['9', '9'], ['10', '10'], ['11', '11'], ['12', '12'],
        ['13', '13'], ['14', '14'], ['15', '15'], ['16', '16'], ['17', '17'], ['18', '18'],
        ['19', '19'], ['20', '20'], ['21', '21'], ['22', '22'], ['23', '23'], ['24', '24'],
        ['25', '25'], ['26', '26'], ['27', '27'], ['28', '28'], ['29', '29'], ['30', '30'],
        ['31', '31'], ['32', '32'], ['33', '33'], ['34', '34'], ['35', '35'], ['36', '36'],
        ['37', '37'], ['38', '38'], ['39', '39'], ['40', '40'], ['41', '41'], ['42', '42'],
        ['43', '43'], ['44', '44'], ['45', '45'], ['46', '46'], ['47', '47'], ['48', '48'],
        ['49', '49'], ['50', '50'], ['51', '51'], ['52', '52'], ['53', '53'], ['54', '54'],
        ['55', '55'], ['56', '56'], ['57', '57'], ['58', '58'], ['59', '59']
    ]
  end
end
