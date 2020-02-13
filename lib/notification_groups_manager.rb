require 'concurrent'

class SslClient
  attr_reader :url, :port

  def initialize(url, port = '443')
    @url = url
    @port = port
  end

  def ping_for_certificate_info
    context = OpenSSL::SSL::SSLContext.new
    tcp_client = TCPSocket.new(url, port)
    ssl_client = OpenSSL::SSL::SSLSocket.new tcp_client, context
    ssl_client.hostname = url
    ssl_client.sync_close = true
    ssl_client.connect
    certificate = ssl_client.peer_cert
    verify_result = ssl_client.verify_result
    tcp_client.close
    {certificate: certificate, verify_result: verify_result }
  rescue => error
    {certificate: nil, verify_result: nil }
  end
end

class NotificationGroupsManager
  Domain = Struct.new(:domain, :scan_port, :notification_group, :x509_cert, :verify_result)

  def self.scan(options = {})
    initialize_database(options[:db])

    ngs = NotificationGroupsSubject.includes(:notification_group, { notification_group: :schedules})
      .where(notification_groups: { status: false })
      .where(schedules: {schedule_type: "#{options[:schedule_type]}", schedule_value: "#{options[:schedule_value]}"})
      .where(["domain_name IS NOT ? and subjectable_id IS ?", nil, nil]).pluck(:domain_name, :scan_port, :notification_group_id)

    subjectable_ids = NotificationGroupsSubject.all.where(subjectable_type: 'CertificateName').pluck(:subjectable_id).compact
    certificate_names = CertificateName.includes(:notification_groups, { notification_groups: :schedules})
      .where(notification_groups: { status: false })
      .where(schedules: {schedule_type: "#{options[:schedule_type]}", schedule_value: "#{options[:schedule_value]}"})
      .where(id: subjectable_ids)

    urls = []
    ngs.each do |notification_group_subject|
      urls << Domain.new(notification_group_subject[0], notification_group_subject[1], notification_group_subject[2], nil, nil)
    end

    certificate_names.each do |cn|
      urls << Domain.new(cn.name, cn.notification_groups.first.scan_port, cn.notification_groups.first.id)
    end

    ScanLog.maximum('scan_group').nil? ? scan_group = 1 : scan_group = ScanLog.maximum('scan_group') + 1
    scan_logs = []
    processed_domains = []

    pool = Concurrent::CachedThreadPool.new
    pool.post do
      urls.uniq.each do |struct|
        ssl_client = SslClient.new(struct.domain.gsub("*.", "www."), struct.scan_port)
        cert_info = ssl_client.ping_for_certificate_info
        struct.x509_cert = cert_info[:certificate]
        struct.verify_result = cert_info[:verify_result]
        processed_domains << struct
      end
    end

    pool.shutdown
    pool.wait_for_termination
    processed_domains.uniq.each do |domain|
      if domain.x509_cert.present?
        certificate = domain.x509_cert
        verify_result = domain.verify_result
        cert_expiration_date = certificate.not_after.to_date
        scan_status = 'expiring'
        if verify_result == 27
          scan_status = 'untrusted'
        elsif DateTime.now.to_date > cert_expiration_date
          scan_status = 'expired'
        elsif !certificate.subject_alternative_names.include? domain.domain
          scan_status = 'name_mismatch'
        end

        scanned_cert = ScannedCertificate.create_with(body: certificate.to_s, decoded: certificate.to_text).find_or_create_by(serial: certificate.serial.to_s)
        scan_logs << ScanLog.new(notification_group_id: domain.notification_group, scanned_certificate_id: scanned_cert.id, domain_name: domain.domain, scan_status: scan_status, expiration_date: cert_expiration_date, scan_group: scan_group)
      else
        scan_logs << ScanLog.new(notification_group_id: domain.notification_group, scanned_certificate_id: nil, domain_name: domain.domain, scan_status: "not_found", expiration_date: nil, scan_group: scan_group)
      end
    end

    ScanLog.import scan_logs
  end

  class << self
    private

    def initialize_database(db_name)
      if Rails.env.development?
        Sandbox.find_by_host('sandbox.ssl.local').use_database
      else
        Sandbox.find_by_host(db_name).use_database
      end
    end
  end
end
