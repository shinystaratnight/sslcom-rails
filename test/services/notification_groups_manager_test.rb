# frozen_string_literal: true

require "test_helper"

describe NotificationGroupsManager do
  include X509Helper

  describe 'NotificationGroupsManager.scan' do
    DomainObject = Struct.new(:url, :scan_port, :notification_group, :x509_cert, :verify_result)

    before(:each) do
      ActionMailer::Base.deliveries.clear
      SslAccount.any_instance.stubs(:initial_setup).returns(true)
      @notification_group = create(:notification_group)
      @notification_group.schedules << create(:schedule, :daily)
    end

    it "scans domains associated with a notification groups succesfully (success case)" do
      SslAccount.any_instance.stubs(:initial_setup).returns(true)
      @notification_group.notification_groups_subjects << create(:notification_groups_subject, :certificate_name_type)
      domain = DomainObject.new('valid.com', @notification_group.scan_port, @notification_group, create_x509_cert('valid.com'), 'ok')

      NotificationGroupsManager.stubs(:manufacture_domains_structs).with('Simple', '2').returns([domain])
      NotificationGroupsManager.scan(db: 'ssl_com_test', schedule_type: 'Simple', schedule_value: '2')

      assert_equal ScannedCertificate.count, 1
      assert_equal ScanLog.count, 1
      assert ScanLog.last.scan_status == 'ok'
    end

    it "scans domains associated with a notification groups succesfully (failure case)" do
      @notification_group.notification_groups_subjects << create(:notification_groups_subject, :certificate_name_type)
      domain = DomainObject.new('notfound.com', @notification_group.scan_port, @notification_group, nil, nil)

      NotificationGroupsManager.stubs(:manufacture_domains_structs).with('Simple', '2').returns([domain])
      NotificationGroupsManager.scan(db: 'ssl_com_test', schedule_type: 'Simple', schedule_value: '2')

      assert_equal ScanLog.count, 1
      assert ScanLog.last.scan_status == 'not_found'
    end

    it "scans domains associated with a notification groups succesfully (untrusted case)" do
      @notification_group.notification_groups_subjects << create(:notification_groups_subject, domain_name: 'untrusted.com')

      domain = DomainObject.new('untrusted.com', @notification_group.scan_port, @notification_group, create_x509_cert('untrusted.com'), 'certificate not trusted')

      NotificationGroupsManager.stubs(:manufacture_domains_structs).with('Simple', '2').returns([domain])
      NotificationGroupsManager.scan(db: 'ssl_com_test', schedule_type: 'Simple', schedule_value: '2')

      assert_equal ScanLog.count, 1
      assert_equal ScannedCertificate.count, 1
      assert ScanLog.last.scan_status == 'certificate not trusted'
      assert ScanLog.last.domain_name == @notification_group.notification_groups_subjects.first.domain_name
    end

    it "scans domains associated with a notification groups succesfully (expired case)" do
      @notification_group.notification_groups_subjects << create(:notification_groups_subject, domain_name: 'expired.com')

      domain = DomainObject.new('expired.com', @notification_group.scan_port, @notification_group, create_x509_cert('expired.com'), 'certificate has expired')

      NotificationGroupsManager.stubs(:manufacture_domains_structs).with('Simple', '2').returns([domain])
      NotificationGroupsManager.scan(db: 'ssl_com_test', schedule_type: 'Simple', schedule_value: '2')

      assert_equal ScanLog.count, 1
      assert_equal ScannedCertificate.count, 1
      assert ScanLog.last.scan_status == 'certificate has expired'
      assert ScanLog.last.domain_name == @notification_group.notification_groups_subjects.first.domain_name
    end

    it "scans domains associated with a notification groups succesfully (name_mismatch case)" do
      @notification_group.notification_groups_subjects << create(:notification_groups_subject, domain_name: 'name_mismatch.com')

      domain =  DomainObject.new('name_mismatch.com', @notification_group.scan_port, @notification_group, create_x509_cert('name_mismatch.com'), 'subject issuer mismatch')

      NotificationGroupsManager.stubs(:manufacture_domains_structs).with('Simple', '2').returns([domain])
      NotificationGroupsManager.scan(db: 'ssl_com_test', schedule_type: 'Simple', schedule_value: '2')

      assert_equal ScanLog.count, 1
      assert_equal ScannedCertificate.count, 1
      assert ScanLog.last.scan_status == 'subject issuer mismatch'
      assert ScanLog.last.domain_name == @notification_group.notification_groups_subjects.first.domain_name
    end

    describe 'scan status change for certificates' do
      it 'sends a domain digest notice if a certificate changes status from one scan to the next' do
        notification_group = create(:notification_group)
        notification_group.schedules << create(:schedule, :daily)
        notification_group.notification_groups_subjects << create(:notification_groups_subject, :certificate_name_type)

        x509_certificate = create_x509_cert('valid.com')
        domain = DomainObject.new('valid.com', notification_group.scan_port, notification_group, x509_certificate, 'ok')

        NotificationGroupsManager.stubs(:manufacture_domains_structs).with('Simple', '2').returns([domain])
        NotificationGroupsManager.scan(db: 'ssl_com_test', schedule_type: 'Simple', schedule_value: '2')

        assert_equal ScannedCertificate.count, 1
        assert_equal ScanLog.count, 1
        assert ScanLog.last.scan_status == 'ok'
        assert_equal ActionMailer::Base.deliveries.size, 1
        assert_equal Ahoy::Message.count, 1

        domain = DomainObject.new('valid.com', notification_group.scan_port, notification_group, x509_certificate, 'certificate not trusted')

        NotificationGroupsManager.stubs(:manufacture_domains_structs).with('Simple', '2').returns([domain])
        NotificationGroupsManager.scan(db: 'ssl_com_test', schedule_type: 'Simple', schedule_value: '2')

        assert_equal ScannedCertificate.count, 1
        assert_equal ScanLog.count, 2
        assert ScanLog.last.scan_status == 'certificate not trusted'
        assert_equal ActionMailer::Base.deliveries.size, 2
        assert_equal Ahoy::Message.count, 2

        domain = DomainObject.new('valid.com', notification_group.scan_port, notification_group, x509_certificate, 'subject issuer mismatch')

        NotificationGroupsManager.stubs(:manufacture_domains_structs).with('Simple', '2').returns([domain])
        NotificationGroupsManager.scan(db: 'ssl_com_test', schedule_type: 'Simple', schedule_value: '2')

        assert_equal ScannedCertificate.count, 1
        assert_equal ScanLog.count, 3
        assert ScanLog.last.scan_status == 'subject issuer mismatch'
        assert_equal ActionMailer::Base.deliveries.size, 3
        assert_equal Ahoy::Message.count, 3
      end
    end
  end

  describe 'NotificationGroupsManager.send_expiration_reminders' do
    before(:each) do
      ActionMailer::Base.deliveries.clear
      SslAccount.any_instance.stubs(:initial_setup).returns(true)

      @notification_group = create(:notification_group)
      ['-15', '0', '15', '30', '60'].each do |reminder_value|
        create(:preference, owner_id: @notification_group.id, value: reminder_value)
      end
    end

    it 'only sends one expiration reminder if mulitple certificates meet expiration criteria' do
      @notification_group.notification_groups_contacts << create(:notification_groups_contact)
      @notification_group.scanned_certificates << create(:scanned_certificate, :expired_today)
      @notification_group.scanned_certificates << create(:scanned_certificate, :expired_15_days_ago)
      @notification_group.scanned_certificates << create(:scanned_certificate, :expires_in_15_days)
      @notification_group.scanned_certificates << create(:scanned_certificate, :expires_in_30_days)
      @notification_group.scanned_certificates << create(:scanned_certificate, :expires_in_60_days)

      NotificationGroupsManager.send_expiration_reminders(db: 'ssl_com_test')
      mail = ActionMailer::Base.deliveries.last

      assert_equal Ahoy::Message.count, 1
      assert_equal ActionMailer::Base.deliveries.size, 1
      assert_equal mail.to.size, 1
    end

    it 'sends one distinct notice (expired today)' do
      @notification_group.notification_groups_contacts << create(:notification_groups_contact)
      @notification_group.scanned_certificates << create(:scanned_certificate, :expired_today)

      NotificationGroupsManager.send_expiration_reminders(db: 'ssl_com_test')
      mail = ActionMailer::Base.deliveries.last

      assert_equal Ahoy::Message.count, 1
      assert_equal ActionMailer::Base.deliveries.size, 1
      assert_equal mail.to.size, 1
    end

    it 'sends one distinct notice (expired 15 days ago)' do
      @notification_group.notification_groups_contacts << create(:notification_groups_contact)
      @notification_group.scanned_certificates << create(:scanned_certificate, :expired_15_days_ago)

      NotificationGroupsManager.send_expiration_reminders(db: 'ssl_com_test')
      mail = ActionMailer::Base.deliveries.last

      assert_equal Ahoy::Message.count, 1
      assert_equal ActionMailer::Base.deliveries.size, 1
      assert_equal mail.to.size, 1
    end

    it 'sends one distinct notice (expiring in 15 days)' do
      @notification_group.notification_groups_contacts << create(:notification_groups_contact)
      @notification_group.scanned_certificates << create(:scanned_certificate, :expires_in_15_days)

      NotificationGroupsManager.send_expiration_reminders(db: 'ssl_com_test')
      mail = ActionMailer::Base.deliveries.last

      assert_equal Ahoy::Message.count, 1
      assert_equal ActionMailer::Base.deliveries.size, 1
      assert_equal mail.to.size, 1
    end

    it 'sends one distinct notice (expiring in 30 days)' do
      @notification_group.notification_groups_contacts << create(:notification_groups_contact)
      @notification_group.scanned_certificates << create(:scanned_certificate, :expires_in_30_days)

      NotificationGroupsManager.send_expiration_reminders(db: 'ssl_com_test')
      mail = ActionMailer::Base.deliveries.last

      assert_equal Ahoy::Message.count, 1
      assert_equal ActionMailer::Base.deliveries.size, 1
      assert_equal mail.to.size, 1
    end

    it 'sends one distinct notice (expiring in 60 days)' do
      @notification_group.notification_groups_contacts << create(:notification_groups_contact)
      @notification_group.scanned_certificates << create(:scanned_certificate, :expires_in_60_days)
      NotificationGroupsManager.send_expiration_reminders(db: 'ssl_com_test')
      mail = ActionMailer::Base.deliveries.last

      assert_equal Ahoy::Message.count, 1
      assert_equal ActionMailer::Base.deliveries.size, 1
      assert_equal mail.to.size, 1
    end

    it 'sends expiration reminders to the correct contacts' do
      @notification_group.notification_groups_contacts << create_list(:notification_groups_contact, 3)
      @notification_group.scanned_certificates << create(:scanned_certificate, :expired_today)

      NotificationGroupsManager.send_expiration_reminders(db: 'ssl_com_test')

      mail = ActionMailer::Base.deliveries.last

      assert_equal Ahoy::Message.count, 1
      assert_equal ActionMailer::Base.deliveries.size, 1
      assert_equal mail['to'].to_s.split.size, 3
      assert mail.to == @notification_group.notification_groups_contacts.pluck(:email_address)
    end

    it 'does not send any expiration reminders if criteria has not been met' do
      @notification_group.notification_groups_contacts << create(:notification_groups_contact)
      @notification_group.scanned_certificates << create(:scanned_certificate, :wont_expire_soon)

      NotificationGroupsManager.send_expiration_reminders(db: 'ssl_com_test')

      assert_equal Ahoy::Message.count, 0
      assert_equal ActionMailer::Base.deliveries.size, 0
    end

    it 'sends multiple emails to contacts that have subscribed to one or more notification groups' do
      @notification_group.notification_groups_contacts << create_list(:notification_groups_contact, 3)
      @notification_group.scanned_certificates << create(:scanned_certificate, :expired_today)
      last_contact = @notification_group.notification_groups_contacts.last.email_address
      second_notification_group = create(:notification_group)
      second_notification_group.notification_groups_contacts << create(:notification_groups_contact, email_address: last_contact)
      second_notification_group.scanned_certificates << create(:scanned_certificate, :expired_today)
      ['-15', '0', '15', '30', '60'].each do |reminder_value|
        create(:preference, owner_id: second_notification_group.id, value: reminder_value)
      end

      NotificationGroupsManager.send_expiration_reminders(db: 'ssl_com_test')
      mail = ActionMailer::Base.deliveries

      assert_equal ActionMailer::Base.deliveries.size, 2
      assert_equal Ahoy::Message.count, 2
      assert mail.first.to.include? last_contact
      assert mail.second.to[0] == last_contact
    end
  end
end
