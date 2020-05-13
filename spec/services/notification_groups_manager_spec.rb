# frozen_string_literal: false

require 'rails_helper'

describe NotificationGroupsManager do
  include ActiveJob::TestHelper
  include X509Helper
  include MailerHelper

  before do
    ActionMailer::Base.deliveries = []
    DatabaseCleaner.start
  end

  after do
    DatabaseCleaner.clean
    clear_email_deliveries
    clear_enqueued_jobs
    clear_performed_jobs
  end

  describe '.scan' do
    DomainObject = Struct.new(:url, :scan_port, :notification_group, :x509_cert, :verify_result)

    let(:notification_group) { FactoryBot.build_stubbed(:notification_group) }
    let(:schedules) { notification_group.schedules << build_stubbed(:schedule, :daily) }
    let(:notification_groups_subjects) { notification_group.notification_groups_subjects << build_stubbed(:notification_groups_subject, :certificate_name_type) }

    context 'when successful' do
      xit 'returns ok' do
        domain = DomainObject.new('valid.com', notification_group.scan_port, notification_group, create_x509_cert('valid.com'), 'ok')

        described_class.stubs(:manufacture_domains_structs).with('Simple', '2').returns([domain])
        described_class.scan(db: 'ssl_com_test', schedule_type: 'Simple', schedule_value: '2')

        expect(ScannedCertificate.count).to be 1
        expect(ScanLog.count).to be 1
        expect(ScanLog.last.scan_status).to eq 'ok'
      end
    end

    context 'when failure' do
      xit "returns 'not found'" do
        domain = DomainObject.new('notfound.com', notification_group.scan_port, notification_group, nil, nil)

        described_class.stubs(:manufacture_domains_structs).with('Simple', '2').returns([domain])
        described_class.scan(db: 'ssl_com_test', schedule_type: 'Simple', schedule_value: '2')

        expect(ScanLog.count).to be 1
        expect(ScanLog.last.scan_status).to eq 'not found'
      end
    end

    context 'when untrusted' do
      xit "returns 'certificate untrusted'" do
        domain = DomainObject.new('untrusted.com', notification_group.scan_port, notification_group, create_x509_cert('untrusted.com'), 'certificate not trusted')

        described_class.stubs(:manufacture_domains_structs).with('Simple', '2').returns([domain])
        described_class.scan(db: 'ssl_com_test', schedule_type: 'Simple', schedule_value: '2')

        expect(ScannedCertificate.count).to be 1
        expect(ScanLog.count).to be 1
        expect(ScanLog.last.scan_status).to eq 'certificate not trusted'
      end
    end

    context 'when host name mismatch' do
      xit "returns 'hostname mismatch'" do
        domain = DomainObject.new('name_mismatch.com', notification_group.scan_port, notification_group, create_x509_cert('name_mismatch.com'), 'hostname mismatch')

        described_class.stubs(:manufacture_domains_structs).with('Simple', '2').returns([domain])
        described_class.scan(db: 'ssl_com_test', schedule_type: 'Simple', schedule_value: '2')

        expect(ScannedCertificate.count).to be 1
        expect(ScanLog.count).to be 1
        expect(ScanLog.last.scan_status).to eq 'hostname mismatch'
      end
    end

    context 'when expired' do
      xit "returns 'certificate has expired'" do
        domain = DomainObject.new('expired.com', notification_group.scan_port, notification_group, create_x509_cert('expired.com'), 'certificate has expired')

        described_class.stubs(:manufacture_domains_structs).with('Simple', '2').returns([domain])
        described_class.scan(db: 'ssl_com_test', schedule_type: 'Simple', schedule_value: '2')

        expect(ScannedCertificate.count).to be 1
        expect(ScanLog.count).to be 1
        expect(ScanLog.last.scan_status).to eq 'certificate has expired'
      end
    end

    context 'when status changes' do
      xit 'sends a domain digest notice' do
        x509_certificate = create_x509_cert('valid.com')
        domain = DomainObject.new('valid.com', notification_group.scan_port, notification_group, x509_certificate, 'ok')

        described_class.stubs(:manufacture_domains_structs).with('Simple', '2').returns([domain])
        described_class.scan(db: 'ssl_com_test', schedule_type: 'Simple', schedule_value: '2')

        domain = DomainObject.new('valid.com', notification_group.scan_port, notification_group, x509_certificate, 'hostname mismatch')

        described_class.stubs(:manufacture_domains_structs).with('Simple', '2').returns([domain])
        described_class.scan(db: 'ssl_com_test', schedule_type: 'Simple', schedule_value: '2')

        expect(Action::MailerBase.deliveries.count).to be 1
        expect(Ahoy::Message.count).to be 1
      end
    end
  end

  describe '.send_expiration_reminders' do
    let(:notification_group) { create(:notification_group, notification_groups_contacts: [create(:notification_groups_contact)]) }

    before do
      ['-15', '0', '15', '30', '60'].each do |reminder_value|
        create(:preference, owner_id: notification_group.id, value: reminder_value)
      end
    end

    after do
      Preference.where(owner_id: notification_group.id, group_type: 'ReminderTrigger').destroy_all
    end

    context 'when a domain expires today' do
      xit 'sends an expiration notice' do
        notification_group.scanned_certificates << create(:scanned_certificate, :expired_today)
        expect_email_to_be_sent
      end

      xit 'sends ahoy message' do
        notification_group.scanned_certificates << create(:scanned_certificate, :expired_today)
        expect { described_class.send_expiration_reminders(db: 'ssl_com_test') }.to change { Ahoy::Message.count }
      end
    end

    context 'when expired 15 days ago' do
      xit 'sends an expiration notice' do
        notification_group.scanned_certificates << create(:scanned_certificate, :expired_15_days_ago)
        expect_email_to_be_sent
      end

      xit 'sends ahoy message' do
        notification_group.scanned_certificates << create(:scanned_certificate, :expired_15_days_ago)
        expect { described_class.send_expiration_reminders(db: 'ssl_com_test') }.to change { Ahoy::Message.count }
      end
    end

    context 'when expires in 15 days' do
      xit 'sends an expiration notice' do
        notification_group.scanned_certificates << create(:scanned_certificate, :expires_in_15_days)
        expect_email_to_be_sent
      end

      xit 'sends ahoy message' do
        notification_group.scanned_certificates << create(:scanned_certificate, :expires_in_15_days)
        expect { described_class.send_expiration_reminders(db: 'ssl_com_test') }.to change { Ahoy::Message.count }
      end
    end

    context 'when expires in 30 days' do
      xit 'sends an expiration notice' do
        notification_group.scanned_certificates << create(:scanned_certificate, :expires_in_30_days)
        expect_email_to_be_sent
      end

      xit 'sends ahoy message' do
        notification_group.scanned_certificates << create(:scanned_certificate, :expires_in_30_days)
        expect { described_class.send_expiration_reminders(db: 'ssl_com_test') }.to change { Ahoy::Message.count }
      end
    end

    context 'when expires in 60 days' do
      xit 'sends an expiration notice' do
        notification_group.scanned_certificates << create(:scanned_certificate, :expires_in_60_days)
        expect_email_to_be_sent
      end
    end

    context 'when multiple expired certificates' do
      xit 'sends an expiration notice for all certs' do
        notification_group.scanned_certificates << create(:scanned_certificate, :expired_today)
        notification_group.scanned_certificates << create(:scanned_certificate, :expired_15_days_ago)
        notification_group.scanned_certificates << create(:scanned_certificate, :expires_in_15_days)
        notification_group.scanned_certificates << create(:scanned_certificate, :expires_in_30_days)
        notification_group.scanned_certificates << create(:scanned_certificate, :expires_in_60_days)
        expect_email_to_be_sent
      end

      xit 'sends ahoy message for all certs' do
        notification_group.scanned_certificates << create(:scanned_certificate, :expired_today)
        notification_group.scanned_certificates << create(:scanned_certificate, :expired_15_days_ago)
        notification_group.scanned_certificates << create(:scanned_certificate, :expires_in_15_days)
        notification_group.scanned_certificates << create(:scanned_certificate, :expires_in_30_days)
        notification_group.scanned_certificates << create(:scanned_certificate, :expires_in_60_days)
        expect { described_class.send_expiration_reminders(db: 'ssl_com_test') }.to change { Ahoy::Message.count }
      end
    end

    context 'when no expirations' do
      xit 'does not send any expiration reminders if criteria has not been met' do
        notification_group.scanned_certificates << create(:scanned_certificate, :wont_expire_soon)
        expect { described_class.send_expiration_reminders(db: 'ssl_com_test') }.to change { email_total_deliveries }.by(0)
      end
    end

    # Developer note: restore test and refactor once scan is stable
    xit 'sends expiration reminders to the correct contacts' do
      notification_group.notification_groups_contacts << create_list(:notification_groups_contact, 3)
      notification_group.scanned_certificates << create(:scanned_certificate, :expired_today)

      described_class.send_expiration_reminders(db: 'ssl_com_test')
      mail = ActionMailer::Base.deliveries.last

      assert_equal Ahoy::Message.count, 1
      assert_equal ActionMailer::Base.deliveries.size, 1
      assert_equal mail['to'].to_s.split.size, 3
      assert mail.to == notification_group.notification_groups_contacts.pluck(:email_address)
    end

    # Developer note: restore test and refactor once scan is stable
    xit 'sends multiple emails to contacts that have subscribed to one or more notification groups' do
      notification_group.notification_groups_contacts << create_list(:notification_groups_contact, 3)
      notification_group.scanned_certificates << create(:scanned_certificate, :expired_today)
      last_contact = notification_group.notification_groups_contacts.last.email_address
      second_notification_group = create(:notification_group)
      second_notification_group.notification_groups_contacts << create(:notification_groups_contact, email_address: last_contact)
      second_notification_group.scanned_certificates << create(:scanned_certificate, :expired_today)
      ['-15', '0', '15', '30', '60'].each do |reminder_value|
        create(:preference, owner_id: second_notification_group.id, value: reminder_value)
      end

      described_class.send_expiration_reminders(db: 'ssl_com_test')
      mail = ActionMailer::Base.deliveries

      assert_equal ActionMailer::Base.deliveries.size, 2
      assert_equal Ahoy::Message.count, 2
      assert mail.first.to.include? last_contact
      assert mail.second.to[0] == last_contact
    end
  end

  def expect_email_to_be_sent
    expect { described_class.send_expiration_reminders(db: 'ssl_com_test') }.to change { email_total_deliveries }
  end
end
