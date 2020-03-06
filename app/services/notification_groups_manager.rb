class NotificationGroupsManager
  DomainObject = Struct.new(:url, :scan_port, :notification_group, :x509_cert, :verify_result)

  def self.scan(options = {})
    initialize_database(options[:db])
    domains = manufacture_domains_structs(options[:schedule_type], options[:schedule_value])

    scan_logs = []
    domains.uniq.each do |domain|
      scan_log = domain.notification_group.scan_logs.last
      if scan_log.nil?
        scan_group = 1
      else
        scan_group = scan_log.scan_group + 1
      end

      if domain.x509_cert.present?
        certificate = domain.x509_cert
        scan_status = domain.verify_result

        scanned_cert = ScannedCertificate.find_or_initialize_by(serial: certificate.serial.to_s)
        if scanned_cert.new_record?
          scanned_cert.body = certificate.to_s
          scanned_cert.decoded = certificate.to_text
          scanned_cert.save
          NotificationGroupMailer.domain_digest_notice(scan_status, domain.notification_group, scanned_cert, domain.url, domain.notification_group.notification_groups_contacts, domain.notification_group.ssl_account).deliver_now
          ScanLog.create(notification_group_id: domain.notification_group.id, scanned_certificate_id: scanned_cert.id, domain_name: domain.url, scan_status: scan_status, expiration_date: certificate.not_after.to_date, scan_group: scan_group)
        else
          if scan_status != scanned_cert.scan_logs.last.scan_status
            NotificationGroupMailer.domain_digest_notice(scan_status, domain.notification_group, scanned_cert, domain.url, domain.notification_group.notification_groups_contacts, domain.notification_group.ssl_account).deliver_now
          end
          scan_logs << ScanLog.new(notification_group_id: domain.notification_group.id, scanned_certificate_id: scanned_cert.id, domain_name: domain.url, scan_status: scan_status, expiration_date: certificate.not_after.to_date, scan_group: scan_group)
        end
      else
        scan_logs << ScanLog.new(notification_group_id: domain.notification_group.id, scanned_certificate_id: nil, domain_name: domain.url, scan_status: "not_found", expiration_date: nil, scan_group: scan_group)
      end
    end
    ScanLog.import scan_logs
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
        NotificationGroupMailer.expiration_notice(ng, expired_certificates, contacts, ssl_account).deliver_now
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

    def manufacture_domains_structs(schedule_type, schedule_value)
      ngs = NotificationGroupsSubject.includes(:notification_group, { notification_group: :schedules})
        .where(notification_groups: { status: false })
        .where(schedules: {schedule_type: schedule_type, schedule_value: schedule_value})
        .where(["domain_name IS NOT ?", nil])

      subjectable_ids = NotificationGroupsSubject.where(subjectable_type: 'CertificateName').pluck(:subjectable_id).compact
      certificate_names = CertificateName.includes(:notification_groups, { notification_groups: :schedules})
        .where(notification_groups: { status: false })
        .where(schedules: {schedule_type: schedule_type, schedule_value: schedule_value})
        .where(id: subjectable_ids)

      domains = []
      ngs.each do |notification_group_subject|
        domains << DomainObject.new(notification_group_subject.domain_name, notification_group_subject.notification_group.scan_port, notification_group_subject.notification_group, nil, nil)
      end

      certificate_names.each do |cn|
        domains << DomainObject.new(cn.name, cn.notification_groups.first.scan_port, cn.notification_groups.first)
      end

      executors = domains.uniq.map do |domain|
        Concurrent::Future.execute({ executor: Concurrent::FixedThreadPool.new(20) }) do
          ssl_client = SslClient.new(domain.url.gsub("*.", "www."), domain.scan_port)
          cert_info = ssl_client.ping_for_certificate_info
          domain.x509_cert = cert_info[:certificate]
          domain.verify_result = cert_info[:verify_result]
          domain
        end
      end
      executors.map(&:value)
    end
  end
end
