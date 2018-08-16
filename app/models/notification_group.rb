class NotificationGroup < ActiveRecord::Base
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

  validates :friendly_name, allow_nil: false, allow_blank: false,
            length: { minimum: 1, maximum: 255 },
            uniqueness: {
                case_sensitive: true,
                scope: :ssl_account_id,
                message: 'Friendly name already exists for this user or team.'
            }

  before_create do |ng|
    ng.ref = 'ng-' + SecureRandom.hex(1) + Time.now.to_i.to_s(32)
  end

  # will_paginate
  cattr_accessor :per_page
  @@per_page = 10

  def to_param
    ref
  end

  def self.auto_manage_email_address(cc, cud, contacts=[])
    notification_groups = cc.certificate_order.notification_groups

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
      notification_groups.each do |group|
        ngs = group.notification_groups_subjects

        if domain
          if cud == 'delete'
            ngs.where(subjectable_type: 'CertificateName', subjectable_id: domain.id, domain_name: nil).destroy_all
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
          cc.certificate_names.each do |cn|
            if cud == 'create'
              ngs.build(
                  subjectable_type: 'CertificateName', subjectable_id: cn.id
              ).save
            elsif cud == 'delete'
              ngs.where(subjectable_type: 'CertificateName', subjectable_id: cn.id, domain_name: nil).destroy_all
              ngs.where(subjectable_type: 'CertificateName', subjectable_id: domain.id)
                  .update_all(subjectable_type: nil, subjectable_id: nil)
            end
          end
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
    contacts.concat ["test@mail.com"]

    domains = []
    domains.concat notification_groups_subjects.where(["domain_name IS NOT ? and subjectable_id IS ?",
                                                       nil,
                                                       nil]).pluck(:domain_name)
    domains.concat CertificateName.where(id: notification_groups_subjects.where(subjectable_type: 'CertificateName')
                                                  .pluck(:subjectable_id)).pluck(:name)

    domains.uniq.each do |domain|
      unless except_certs.(domain, except_list)
        scan_status = 'ok'
        ssl_domain_connect(domain.gsub("*.", "www."), scan_port)

        if ssl_client
          cert = domain_certificate
          expiration_date = cert.not_after unless cert.blank?

          if expiration_date
            exp_dates.each_with_index do |ed, i|
              if (i < exp_dates.count - 1) &&
                  (expiration_date < ed.to_i.days.from_now) &&
                  (expiration_date >= exp_dates[i + 1].days.from_now)
                results << Struct::Notification.new(ed, exp_dates[i + 1], domain, expiration_date)
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

          scanned_cert = ScannedCertificate.create body: cert.to_s, decoded: cert.to_text
        else
          scan_status = 'not_found'
          scanned_cert = nil
        end

        scan_logs.build(
            scanned_certificate: scanned_cert,
            domain_name: domain,
            scan_status: scan_status
        ).save
      end
    end

    unless results.empty?
      results.each do |result|
        logger.info "Sending reminder"
        d = [",," + contacts.uniq.join(";")]
        body = Reminder.domain_digest_notice(d)
        body.deliver unless body.to.empty?

        logger.info "create SentReminder"
        SentReminder.create(trigger_value: [result.before, result.after].join(", "),
                            expires_at: result.expire,
                            subject: result.domain,
                            body: body,
                            recipients: contacts.uniq.join(";"))
      end
    end
  end

  def ssl_domain_connect(url, default_port)
    context = OpenSSL::SSL::SSLContext.new
    Timeout.timeout(30) do
      domain, ori_port = url.split ":"
      tcp_client = TCPSocket.new(domain, ori_port || default_port)
      self.ssl_client = OpenSSL::SSL::SSLSocket.new tcp_client, context
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
end
