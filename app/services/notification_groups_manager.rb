class NotificationGroupsManager
  DomainObject = Struct.new(:url, :scan_port, :notification_group, :x509_cert, :verify_result)

  def self.scan(options = {})
    initialize_database(options[:db])
    scan_logs = []

    manufacture_domains_structs(options[:schedule_type], options[:schedule_value])
  end

  def self.send_expiration_reminders(db_name)
    initialize_database(db_name)

    NotificationGroup.includes(:ssl_account, :scanned_certificates, :notification_groups_contacts).find_each do |ng|
      reminders = Preference.where("owner_id = ? AND group_type = ?", ng.id, "ReminderTrigger").pluck(:value).sort.map(&:to_i)
      ssl_account = ng.ssl_account.acct_number || ng.ssl_account.ssl_slug
      contacts = ng.notification_groups_contacts
      scanned_certificates = ng.scanned_certificates
      expired_certificates = []

      scanned_certificates.each do |scanned_cert|
        expiration_date = scanned_cert.not_after.to_date
        if (Date.today == (expiration_date - reminders[0].day))
          expired_certificates << scanned_cert
          break
        elsif (Date.today == (expiration_date - reminders[1].day))
          expired_certificates << scanned_cert
          break
        elsif (Date.today == (expiration_date - reminders[2].day))
          expired_certificates << scanned_cert
          break
        elsif (Date.today == (expiration_date - reminders[3].day))
          expired_certificates << scanned_cert
          break
        elsif (Date.today == (expiration_date - reminders[4].day))
          expired_certificates << scanned_cert
          break
        end
      end

      if expired_certificates.any?
        NotificationGroupMailer.expiration_notice(ng, expired_certificates, contacts.pluck(:email_address).uniq, ssl_account).deliver_later
      end
    end
  end

  class << self
    private

    def initialize_database(db_name)
      if Rails.env.development?
        Sandbox.find_by_host('sandbox.ssl.local').use_database
      elsif Rails.env.production?
        Sandbox.find_by_host(db_name).use_database
      end
    end

    def create_scan_log(ng, scanned_cert, domain, scan_status, exp_date, scan_group)
      if scanned_cert.present?
        scanned_cert = scanned_cert.id
      else
        scanned_cert = nil
      end
      ScanLog.create(notification_group_id: ng.id, scanned_certificate_id: scanned_cert, domain_name: domain.url, scan_status: scan_status, expiration_date: exp_date, scan_group: scan_group)
    end

    def manufacture_domains_structs(schedule_type, schedule_value)
      domains = []

      NotificationGroupsSubject.includes(:notification_group, { notification_group: :schedules})
        .where(notification_groups: { status: false })
        .where(schedules: {schedule_type: schedule_type, schedule_value: schedule_value})
        .where(["domain_name IS NOT ?", nil]).find_each do |ngs|
          domains << DomainObject.new(ngs.domain_name, ngs.notification_group.scan_port, ngs.notification_group, nil, nil)
        end

      subjectable_ids = NotificationGroupsSubject.where(subjectable_type: 'CertificateName').pluck(:subjectable_id).compact
      CertificateName.includes(:notification_groups, { notification_groups: :schedules})
        .where(notification_groups: { status: false })
        .where(schedules: {schedule_type: schedule_type, schedule_value: schedule_value})
        .where(id: subjectable_ids).find_each do |cn|
          domains << DomainObject.new(cn.name, cn.notification_groups.first.scan_port, cn.notification_groups.first, nil, nil)
        end

      domains = domains.uniq
      domains.each_slice(1000) do |domains|
        domains.each do |domain|
          scan_log = domain.notification_group.scan_logs.last
          if scan_log.nil?
            scan_group = 1
          else
            scan_group = scan_log.scan_group + 1
          end
          delay.scan_domain(domain,scan_group)
        end
      end
    end

    def scan_domain(domain,scan_group)
      ssl_client = SslClient.new(domain.url.gsub("*.", "www."), domain.scan_port)
      domain.x509_cert = ssl_client.retrieve_x509_cert
      domain.verify_result = ssl_client.verify_result
      certificate = domain.x509_cert
      domain.verify_result.nil? ? scan_status = 'not found' : scan_status = domain.verify_result

      if certificate.present?
        scanned_cert = ScannedCertificate.find_or_initialize_by(serial: certificate.serial.to_s)
        if scanned_cert.new_record?
          scanned_cert.body = certificate.to_s
          scanned_cert.decoded = certificate.to_text
          scanned_cert.save
        else
          last_scan = ScanLog.where(scanned_certificate_id: scanned_cert.id, notification_group_id: domain.notification_group.id).last
          if Setttings.send_domain_digest_notice && (scan_status != last_scan.scan_status)
            NotificationGroupMailer.domain_digest_notice(scan_status, domain.notification_group, scanned_cert, domain.url, domain.notification_group.notification_groups_contacts.pluck(:email_address).uniq, domain.notification_group.ssl_account).deliver_later
          end
        end
        create_scan_log(domain.notification_group, scanned_cert, domain, scan_status, certificate.not_after.to_date, scan_group)
      else
        create_scan_log(domain.notification_group, nil, domain, scan_status, nil, scan_group)
      end
    end
  end
end
