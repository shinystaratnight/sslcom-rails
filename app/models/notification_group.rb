class NotificationGroup < ApplicationRecord
  belongs_to :ssl_account

  has_many  :notification_groups_contacts, dependent: :destroy
  has_many  :contacts, through: :notification_groups_contacts,
            source: :contactable, source_type: 'Contact'
  has_many  :notification_groups_subjects, dependent: :destroy
  has_many  :certificate_orders, through: :notification_groups_subjects,
            source: :subjectable, source_type: 'CertificateOrder'
  has_many  :certificate_contents, through: :notification_groups_subjects,
            source: :subjectable, source_type: 'CertificateContent'
  has_many  :certificate_names, through: :notification_groups_subjects,
            source: :subjectable, source_type: 'CertificateName'
  has_many  :schedules
  has_many  :scan_logs

  attr_accessor :ssl_client

  preference  :notification_group_triggers, :string

  # validates :friendly_name, allow_nil: false, allow_blank: false,
  #           length: { minimum: 1, maximum: 255 }

  before_create do |ng|
    ng.ref = 'ng-' + SecureRandom.hex(1) + Time.now.to_i.to_s(32)
    ng.friendly_name = ng.ref if ng.friendly_name.blank?
  end

  # will_paginate
  cattr_accessor :per_page
  @@per_page = 10

  def to_param
    ref
  end

  def self.auto_manage_email_address(cc, cud, contacts=[])
    notification_groups = cc.certificate_order.notification_groups.includes(:notification_groups_contacts)

    if notification_groups
      notification_groups.each do |group|
        ngc = group.notification_groups_contacts

        contacts.each do |contact|
          if cud == 'delete'
            ngc.where(contactable_id: contact.id, email_address: nil).destroy_all
            ngc.where(contactable_id: contact.id).update_all(contactable_type: nil, contactable_id: nil)
          elsif cud == 'update'
            ngc.where(["contactable_id = ? and email_address IS NOT ?",
                       contact.id,
                       nil]).update_all(email_address: contact.email)
          end
        end
      end
    end
  end

  def self.auto_manage_cert_name(cc, cud, domain=nil)
    notification_groups = cc.certificate_order.notification_groups

    if notification_groups
      notification_groups.includes(:notification_groups_subjects).each do |group|
        ngs = group.notification_groups_subjects

        if domain
          if cud == 'delete'
            ngs.where(subjectable_type: 'CertificateName', subjectable_id: domain.id, domain_name: nil).delete_all
            ngs.where(subjectable_type: 'CertificateName', subjectable_id: domain.id)
                .update_all(subjectable_type: nil, subjectable_id: nil)
          elsif cud == 'update'
            ngs.where([
                          "subjectable_type = ? and subjectable_id = ? and domain_name IS NOT ?",
                          "CertificateName",
                          domain.id,
                          nil
                      ]).update_all(domain_name: domain.name)
          end
        else
          ngs_batch=[]
          cc.certificate_names.includes(:notification_groups_subjects).each do |cn|
            if cud == 'create'
              ngs_batch << cn.notification_groups_subjects.new(notification_group_id: group.id) if cn.notification_groups_subjects.
                  empty?{|s|s.notification_group_id==group.id}
            elsif cud == 'delete'
              ngs.where(subjectable_type: 'CertificateName', subjectable_id: cn.id, domain_name: nil).delete_all
              ngs.where(subjectable_type: 'CertificateName', subjectable_id: domain.id)
                  .update_all(subjectable_type: nil, subjectable_id: nil)
            end
          end
          NotificationGroupsSubject.import ngs_batch
        end
      end
    end
  end

  # def signed_certificates
  #   certificate_orders.
  #       map(&:certificate_contents).flatten.compact.
  #       map(&:csr).flatten.compact.
  #       map(&:signed_certificates)
  # end
  #
  # def unique_signed_certificates
  #   ([]).tap do |result|
  #     tmp_certs={}
  #     signed_certificates.flatten.compact.each do |sc|
  #       if tmp_certs[sc.common_name]
  #         tmp_certs[sc.common_name] << sc
  #       else
  #         tmp_certs.merge! sc.common_name => [sc]
  #       end
  #     end
  #
  #     tmp_certs
  #     tmp_certs.each do |k, v|
  #       result << tmp_certs[k].max{ |a, b| a.expiration_date <=> b.expiration_date }
  #     end
  #   end
  # end
  #
  # def unrenewed_signed_certificates
  #   unique_signed_certificates.select{ |sc| sc.certificate_order.renewal.blank? }
  # end
  #
  # def renewed?(sc, renew_date)
  #   eds = SignedCertificate.where(:common_name=>sc.common_name).
  #       map(&:expiration_date).compact.sort
  #   eds.detect do |ed|
  #     ed > renew_date.days.from_now
  #   end
  # end
  #
  # def expiring_certificates_in_group
  #   results = []
  #   exp_dates = ReminderTrigger.all.map do |rt|
  #     preferred_notification_group_triggers(rt).to_i
  #   end.sort{ |a, b| b <=> a}
  #
  #   unrenewed_signed_certificates.compact.each do |sc|
  #     sed = sc.expiration_date
  #     unless sed.blank?
  #       exp_dates.each_with_index do |ed, i|
  #         if (i < exp_dates.count - 1) && (sed < ed.to_i.days.from_now) && (sed >= exp_dates[i + 1].days.from_now)
  #           results << Struct::Notification.new(ed, exp_dates[i + 1], sc) unless
  #               renewed?(sc, exp_dates.first.to_i)
  #         end
  #       end
  #     end
  #   end
  #   results
  # end
  #
  # def expired_certificates_in_group(intervals, years_back = 1)
  #   year_in_days = 365
  #   (Array.new(intervals.count){ |i| i = [] }).tap do |results|
  #     unrenewed_signed_certificates.compact.each do |sc|
  #       sed = sc.expiration_date
  #       unless sed.blank?
  #         years_back.times do |i|
  #           years = year_in_days * (i + 1)
  #           adj_int = intervals.map{ |idx| idx + years }
  #           adj_int.each_with_index do |ed, interval|
  #             if (interval < adj_int.count - 1) && (sed < ed.to_i.days.ago) && (sed >= adj_int[interval + 1].days.ago)
  #               results[interval] << Struct::Notification.new(ed, adj_int[interval + 1], sc) unless
  #                   renewed?(sc, intervals.last)
  #               break
  #             end
  #           end
  #         end
  #       end
  #     end
  #   end
  # end
  #
  # def send_and_create_reminders(expired_certs, digest, past = false, interval = nil)
  #   expired_certs.each do |ec|
  #     except_list = %w(
  #         hepsi danskhosting webcruit
  #         epsa\.com\.co
  #         magicexterminating suburbanexterminating)
  #     except_certs = ->(domain, exempt){
  #       exempt.find do |e|
  #         domain=~eval("/#{e}/")
  #       end
  #     }
  #
  #     cert = ec.cert
  #     contact_ids = cert.certificate_order.certificate_contents.flatten.compact
  #                       .map(&:certificate_contacts).flatten.compact.map(&:id)
  #     sltd_contact_ids = notification_groups_contacts.where.not(contactable_id: nil).pluck(:contactable_id).uniq
  #     sltd_contact_ids &= contact_ids
  #
  #     contacts = Contact.where(id: sltd_contact_ids).pluck(:first_name, :last_name, :email).
  #         concat(notification_groups_contacts.where(contactable_id: nil)
  #                    .pluck(:contactable_type, :contactable_type, :email_address).uniq).uniq
  #
  #     contacts.uniq.compact.each do |contact|
  #       unless SentReminder.exists?(trigger_value: [ec.before, ec.after].join(', '),
  #                            expires_at: cert.expiration_date,
  #                            subject: cert.common_name,
  #                            recipients: contact[2]) || except_certs.(cert.common_name, except_list)
  #         d_key = contact.join(', ')
  #         if digest[d_key].blank?
  #           digest.merge!({ d_key => [ec] })
  #         else
  #           digest[d_key] << ec
  #         end
  #       end
  #     end
  #   end
  #
  #   unless digest.empty?
  #     digest.each do |d|
  #       u_certs = d[1].map(&:cert).map(&:common_name).uniq.compact
  #       begin
  #         unless u_certs.empty?
  #           logger.info "Sending reminder"
  #           body = past ? Reminder.past_expired_digest_notice(d, interval) :
  #                      Reminder.digest_notice(d)
  #           body.deliver unless body.to.empty?
  #         end
  #
  #         d[1].each do |ec|
  #           logger.info "create SentReminder"
  #           SentReminder.create(trigger_value: [ec.before, ec.after].join(", "),
  #                               expires_at: ec.cert.expiration_date,
  #                               signed_certificate_id: ec.cert.id,
  #                               subject: ec.cert.common_name,
  #                               body: body,
  #                               recipients: d[0].split(",").last)
  #         end
  #       rescue Exception=>e
  #         logger.error e.backtrace.inspect
  #         raise e
  #       end
  #     end
  #   end
  # end
  #
  # def self.scan_notification_group(group)
  #   certs = group.expiring_certificates_in_group
  #   digest = {}
  #   group.send_and_create_reminders(certs, digest)
  #
  #   digest.clear
  #   intervals = [-30, -7, 16, 31]
  #   certs = group.expired_certificates_in_group(intervals).flatten.compact
  #   group.send_and_create_reminders(certs, digest, true, intervals)
  # end

  def scan_notification_group
    exp_dates = ReminderTrigger.all.map do |rt|
      preferred_notification_group_triggers(rt).to_i
    end.sort{ |a, b| b <=> a}

    except_list = %w(
          hepsi danskhosting webcruit
          epsa\.com\.co
          magicexterminating suburbanexterminating)
    except_certs = ->(domain, exempt){
      exempt.find do |e|
        domain=~eval("/#{e}/")
      end
    }

    results = []
    contacts = []
    contacts.concat notification_groups_contacts.where(["email_address IS NOT ? and contactable_id IS ?",
                                                        nil,
                                                        nil]).pluck(:email_address)
    contacts.concat Contact.where(id: notification_groups_contacts.where(contactable_type: 'CertificateContact')
                                                 .pluck(:contactable_id)).pluck(:email)

    domains = []
    domains.concat notification_groups_subjects.where(["domain_name IS NOT ? and subjectable_id IS ?",
                                                       nil,
                                                       nil]).pluck(:domain_name)
    domains.concat CertificateName.where(id: notification_groups_subjects.where(subjectable_type: 'CertificateName')
                                                  .pluck(:subjectable_id)).pluck(:name)

    last_group_number = scan_logs.maximum('scan_group')
    domains.uniq.each do |domain|
      unless except_certs.(domain, except_list)
        scan_status = 'expiring'
        expiration_date = nil
        ssl_domain_connect(domain.gsub("*.", "www."), scan_port)

        if ssl_client
          cert = domain_certificate
          # expiration_date = cert.not_after unless cert.blank?
          scanned_cert = ScannedCertificate.create_with(
              body: cert.to_s,
              decoded:cert.to_text
          ).find_or_create_by(
              serial: cert.serial.to_s
          )
          expiration_date = cert.blank? ? nil : cert.not_after

          if expiration_date
            exp_dates.each_with_index do |ed, i|
              if (i < exp_dates.count - 1) &&
                  (expiration_date < ed.to_i.days.from_now) &&
                  (expiration_date >= exp_dates[i + 1].days.from_now) &&
                  (expiration_date >= DateTime.now.to_date)
                results << Struct::Notification.new(ed, exp_dates[i + 1],
                                                    domain, expiration_date, scan_status, scanned_cert.id)
              end
            end
          end

          if ssl_client.verify_result == '27'
            scan_status = 'untrusted'
          elsif expiration_date && expiration_date < DateTime.now.to_date
            scan_status = 'expired'
          elsif !cert.subject_alternative_names.include? domain
            scan_status = 'name_mismatch'
          end

          if notify_all.nil? && scan_status != 'expiring'
            results << Struct::Notification.new(nil, nil, domain, expiration_date, scan_status, scanned_cert.id)
          end
          ssl_client.close
        else
          scan_status = 'not_found'
          scanned_cert = nil

          if notify_all.nil?
            results << Struct::Notification.new(nil, nil, domain, nil, scan_status, scanned_cert)
          end
        end

        scan_logs.create(
            scanned_certificate: scanned_cert,
            domain_name: domain,
            scan_status: scan_status,
            expiration_date: expiration_date,
            scan_group: last_group_number ? (last_group_number + 1) : 1
        )
      end
    end

    unless results.empty? or contacts.empty?
      results.each do |result|
        # only email in the event a change of status occurred
        if SentReminder.order("created_at DESC").find_by(trigger_value: [result.before, result.after].join(", "),
                               expires_at: result.expire,
                               subject: result.domain,
                               recipients: contacts.uniq.join(";")).try(:reminder_type)!=result.reminder_type
          logger.info "Sending reminder"
          d = [",," + contacts.uniq.join(";")]
          body = Reminder.domain_digest_notice(d, result, self)
          body.deliver unless body.to.empty?
          logger.info "create SentReminder"
          SentReminder.create(trigger_value: [result.before, result.after].join(", "),
                              expires_at: result.expire,
                              subject: result.domain,
                              body: body,
                              recipients: contacts.uniq.join(";"),
                              reminder_type: result.reminder_type)
        end
      end
    end
  end

  def ssl_domain_connect(url, default_port,timeout=3)
    context = OpenSSL::SSL::SSLContext.new
    Timeout.timeout(timeout) do
      domain, ori_port = url.split ":"
      tcp_client = TCPSocket.new(domain, ori_port || default_port)
      self.ssl_client = OpenSSL::SSL::SSLSocket.new tcp_client, context
      self.ssl_client.hostname = domain
      self.ssl_client.sync_close=true
      self.ssl_client.connect
    end
  rescue
    self.ssl_client = nil
  end

  def domain_certificate
    certs = ssl_client.peer_cert_chain_with_openssl_extension
    unless certs.blank?
      certs.first
    end
  end

  # Scan the domains belongs to notification groups and sending a reminder if expiration date is in reminder days what has been set"
  def self.scan(options={})
    Sandbox.find_by_host(options[:db]).use_database unless options[:db].blank?
    current = DateTime.now
    month = current.strftime("%m").to_i.to_s
    day = current.strftime("%d").to_i.to_s
    week_day = current.strftime("%w")
    hour = current.strftime("%H").to_i.to_s
    minute = current.strftime("%M").to_i.to_s

    NotificationGroup.includes(:notification_groups_subjects, :notification_groups_contacts, :schedules).find_each do |group|
      schedules = {}
      group.schedules.each do |arr|
        if schedules[arr.schedule_type].blank?
          schedules[arr.schedule_type] = arr.schedule_value
        else
          schedules[arr.schedule_type] = (schedules[arr.schedule_type] + '|' + arr.schedule_value.to_s).split('|').sort.join('|')
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
      group.scan_notification_group if run_scan && !group.status
    end
  end

  def set_schedule_to_daily_scan
    schedules.create(schedule_type: 'Simple', schedule_value: 2) if schedules.blank?
    # current_schedules = schedules.pluck(:schedule_type)
    # if current_schedules.include? 'Simple'
    #   schedules.last.update_attribute(:schedule_value, 2) unless schedules.last.schedule_value == 2
    # else
    #   schedules.destroy_all
    #   schedules.build(schedule_type: 'Simple', schedule_value: 2).save
    # end
  end
end
