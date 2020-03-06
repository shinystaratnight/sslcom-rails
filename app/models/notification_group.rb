# frozen_string_literal: true

# == Schema Information
#
# Table name: notification_groups
#
#  id             :integer          not null, primary key
#  friendly_name  :string(255)      not null
#  notify_all     :boolean          default(TRUE)
#  ref            :string(255)      not null
#  scan_port      :string(255)      default("443")
#  status         :boolean
#  created_at     :datetime
#  updated_at     :datetime
#  ssl_account_id :integer
#
# Indexes
#
#  index_notification_groups_on_ssl_account_id          (ssl_account_id)
#  index_notification_groups_on_ssl_account_id_and_ref  (ssl_account_id,ref)

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
      scan_logs = []
      domains.each do |domain|
        ssl_client = SslClient.new(domain.gsub("*.", "www."), self.scan_port)
        results = ssl_client.ping_for_certificate_info

        if results[:certificate].present?
          certificate = results[:certificate]
          scan_status =  results[:verify_result]

          scanned_cert = ScannedCertificate.find_or_initialize_by(serial: certificate.serial.to_s)
          if scanned_cert.new_record?
            scanned_cert.body = certificate.to_s
            scanned_cert.decoded = certificate.to_text
            scanned_cert.save
            ScanLog.create(notification_group_id: self.id, scanned_certificate_id: scanned_cert.id, domain_name: domain, scan_status: scan_status, expiration_date: certificate.not_after.to_date, scan_group: scan_group)
          else
            if scan_status != scanned_cert.scan_logs.last.scan_status
              NotificationGroupMailer.domain_digest_notice(scan_status, self, scanned_cert, domain, self.notification_groups_contacts, self.ssl_account).deliver_now
            end
            scan_logs << ScanLog.new(notification_group_id: self.id, scanned_certificate_id: scanned_cert.id, domain_name: domain, scan_status: scan_status, expiration_date: certificate.not_after.to_date, scan_group: scan_group)
          end
        else
          scan_logs << ScanLog.new(notification_group_id: self.id, scanned_certificate_id: nil, domain_name: domain, scan_status: "not_found", expiration_date: nil, scan_group: scan_group)
        end
      end
      ScanLog.import scan_logs
    end
  end

  # Scan the domains belongs to notification groups and sending a reminder if expiration date is in reminder days what has been set"
  # def self.scan(options={})
  #   Sandbox.find_by_host(options[:db]).use_database unless options[:db].blank?
  #   current = DateTime.now
  #   month = current.strftime("%m").to_i.to_s
  #   day = current.strftime("%d").to_i.to_s
  #   week_day = current.strftime("%w")
  #   hour = current.strftime("%H").to_i.to_s
  #   minute = current.strftime("%M").to_i.to_s
  #
  #   NotificationGroup.includes(:notification_groups_subjects, :notification_groups_contacts, :schedules).find_each do |group|
  #     schedules = {}
  #     group.schedules.each do |arr|
  #       if schedules[arr.schedule_type].blank?
  #         schedules[arr.schedule_type] = arr.schedule_value
  #       else
  #         schedules[arr.schedule_type] = (schedules[arr.schedule_type] + '|' + arr.schedule_value.to_s).split('|').sort.join('|')
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
  #     group.scan_notification_group if run_scan && !group.status
  #   end
  # end
end
