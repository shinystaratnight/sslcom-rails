class NotificationGroup < ApplicationRecord
  include Pagable

  belongs_to :ssl_account

  has_many  :notification_groups_contacts, dependent: :destroy
  has_many  :contacts, through: :notification_groups_contacts, source: :contactable, source_type: 'Contact'
  has_many  :notification_groups_subjects, dependent: :destroy
  has_many  :certificate_orders, through: :notification_groups_subjects, source: :subjectable, source_type: 'CertificateOrder'
  has_many  :certificate_contents, through: :notification_groups_subjects, source: :subjectable, source_type: 'CertificateContent'
  has_many  :certificate_names, through: :notification_groups_subjects, source: :subjectable, source_type: 'CertificateName'
  has_many  :schedules, dependent: :destroy
  has_many  :scan_logs, dependent: :destroy
  has_many :scanned_certificates, -> { distinct }, through: :scan_logs

  preference :notification_group_triggers, :string

  alias_attribute :disabled, :status

  before_create do |ng|
    ng.ref = 'ng-' + SecureRandom.hex(1) + Time.now.to_i.to_s(32)
    ng.friendly_name = ng.ref if ng.friendly_name.blank?
  end

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

  def scan
    if scan_logs.last.nil?
      scan_group = 1
    else
      scan_group = scan_logs.last.scan_group + 1
    end

    domains = []
    domains << notification_groups_subjects.map(&:domain_name).compact
    domains << certificate_names.map(&:name).compact
    domains.flatten!.uniq!

    if domains.any?
      domains.each do |domain|
        delay.scan_domain(domain, scan_group)
      end
    end
  end

  def scan_domain(domain, scan_group)
    ssl_client = SslClient.new(domain.gsub("*.", "www."), self.scan_port)
    certificate = ssl_client.retrieve_x509_cert
    scan_status = ssl_client.verify_result

    if certificate.present?
      scanned_cert = ScannedCertificate.find_or_initialize_by(serial: certificate.serial.to_s)
      if scanned_cert.new_record?
        scanned_cert.body = certificate.to_s
        scanned_cert.decoded = certificate.to_text
        scanned_cert.save
      end
      create_scan_log(self, scanned_cert, domain, scan_status, certificate.not_after.to_date, scan_group)
    else
      scan_status = 'not found' if scan_status.nil?
      create_scan_log(self, nil, domain, scan_status, nil, scan_group)
    end
    send_domain_digest(scan_status, self, scanned_cert, domain, self.notification_groups_contacts, self.ssl_account)
  end

  private

  def send_domain_digest(scan_status, ng, scanned_cert, domain, contacts, ssl_account)
    NotificationGroupMailer.domain_digest_notice(scan_status, ng, scanned_cert, domain, contacts.pluck(:email_address).uniq, ssl_account).deliver_later
  end

  def create_scan_log(ng, scanned_cert, domain, scan_status, exp_date, scan_group)
    ScanLog.create(notification_group_id: ng.id, scanned_certificate_id: scanned_cert, domain_name: domain, scan_status: scan_status, expiration_date: exp_date, scan_group: scan_group)
  end
end
