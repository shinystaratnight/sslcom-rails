class NotificationGroupsManager
  Domain = Struct.new(:url, :scan_port, :notification_group, :x509_cert, :verify_result)

  def self.scan(options = {})
    initialize_database(options[:db])
    domains = manufacture_domains_structs(options[:schedule_type], options[:schedule_value])
    processed_domains = process_domains(domains)

    scan_logs = []
    processed_domains.uniq.each do |domain|
      scan_log = NotificationGroup.find_by_id(domain.notification_group).scan_logs.last
      if scan_log.nil?
        scan_group = 1
      else
        scan_group = scan_log.scan_group + 1
      end

      if domain.x509_cert.present?
        certificate = domain.x509_cert
        verify_result = domain.verify_result
        cert_expiration_date = certificate.not_after.to_date
        scan_status = 'expiring'
        if verify_result == 27
          scan_status = 'untrusted'
        elsif Date.today > cert_expiration_date
          scan_status = 'expired'
        elsif !certificate.subject_alternative_names.include? domain.url
          scan_status = 'name_mismatch'
        end

        scanned_cert = ScannedCertificate.create_with(body: certificate.to_s, decoded: certificate.to_text).find_or_create_by(serial: certificate.serial.to_s)
        scan_logs << ScanLog.new(notification_group_id: domain.notification_group, scanned_certificate_id: scanned_cert.id, domain_name: domain.url, scan_status: scan_status, expiration_date: cert_expiration_date, scan_group: scan_group)
      else
        scan_logs << ScanLog.new(notification_group_id: domain.notification_group, scanned_certificate_id: nil, domain_name: domain.url, scan_status: "not_found", expiration_date: nil, scan_group: scan_group)
      end
    end

    ScanLog.import scan_logs
  end

  def self.send_expiration_reminders(db_name)
    initialize_database(db_name)

    notification_groups = NotificationGroup.includes(:ssl_account, :scanned_certificates, :notification_groups_contacts)
    notification_groups.each do |ng|
      ssl_account = ng.ssl_account.acct_number || ng.ssl_account.ssl_slug
      expiration_reminders = Preference.where(owner_id: ng.id).pluck(:value).map(&:to_i).sort
      contacts = ng.notification_groups_contacts
      scanned_certificates = ng.scanned_certificates.uniq
      expired_certificates = []

      scanned_certificates.each do |scanned_cert|
        expiration_date = scanned_cert.not_after.to_date
        expiration_reminders.each do |reminder|
          if (Date.today == (expiration_date - reminder.day))
            expired_certificates << scanned_cert
          end
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
        .where(["domain_name IS NOT ? and subjectable_id IS ?", nil, nil]).pluck(:domain_name, :scan_port, :notification_group_id)

      subjectable_ids = NotificationGroupsSubject.all.where(subjectable_type: 'CertificateName').pluck(:subjectable_id).compact
      certificate_names = CertificateName.includes(:notification_groups, { notification_groups: :schedules})
        .where(notification_groups: { status: false })
        .where(schedules: {schedule_type: schedule_type, schedule_value: schedule_value})
        .where(id: subjectable_ids)

      domains = []
      ngs.each do |notification_group_subject|
        domains << Domain.new(notification_group_subject[0], notification_group_subject[1], notification_group_subject[2], nil, nil)
      end

      certificate_names.each do |cn|
        domains << Domain.new(cn.name, cn.notification_groups.first.scan_port, cn.notification_groups.first.id)
      end
      domains
    end

    def process_domains(domains)
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
