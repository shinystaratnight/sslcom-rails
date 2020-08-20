# frozen_string_literal: true
require 'rails_helper'

describe NotificationGroup do
  include X509Helper

  before(:all) do
    ActionMailer::Base.deliveries.clear
  end

  let!(:notification_group) { build_stubbed(:notification_group) }

  xit 'scans domains associated with a notification groups succesfully (success case: notification_group_subject)' do
    notification_group.stubs(:notification_groups_subjects).returns([build_stubbed(:notification_groups_subject, :certificate_name_type)])
    domain = notification_group.notification_groups_subjects.first.domain_name

    SslClient.any_instance.stubs(:retrieve_x509_cert).returns(create_x509_cert(domain))
    SslClient.any_instance.stubs(:verify_result).returns('ok')
    notification_group.scan

    assert_equal ScannedCertificate.count, 1
    assert_equal ScanLog.count, 1
    assert ScanLog.last.scan_status == 'ok'
    assert_equal ActionMailer::Base.deliveries.size, 1
    assert_equal Ahoy::Message.count, 1
  end

  xit 'scans domains associated with a notification groups succesfully (success case: certificate_name)' do
    notification_group.stubs(:certificate_names).returns([build_stubbed(:certificate_name)])
    domain = notification_group.certificate_names.first.name

    SslClient.any_instance.stubs(:retrieve_x509_cert).returns(create_x509_cert(domain))
    SslClient.any_instance.stubs(:verify_result).returns('ok')
    notification_group.scan

    assert_equal ScannedCertificate.count, 1
    assert_equal ScanLog.count, 1
    assert ScanLog.last.scan_status == 'ok'
    assert_equal ActionMailer::Base.deliveries.size, 1
    assert_equal Ahoy::Message.count, 1
  end

  xit 'scans domains associated with a notification groups succesfully (failure case)' do
    notification_group.stubs(:notification_groups_subjects).returns([build_stubbed(:notification_groups_subject, :certificate_name_type)])
    domain = notification_group.notification_groups_subjects.first.domain_name

    SslClient.any_instance.stubs(:retrieve_x509_cert).returns(nil)
    SslClient.any_instance.stubs(:verify_result).returns('not found')

    notification_group.scan

    assert_equal ScannedCertificate.count, 0
    assert_equal ScanLog.count, 1
    assert ScanLog.last.scan_status == 'not found'
    assert_equal ActionMailer::Base.deliveries.size, 1
    assert_equal Ahoy::Message.count, 1
  end

  xit 'scans domains associated with a notification groups succesfully (untrusted case)' do
    notification_group.stubs(:notification_groups_subjects).returns([build_stubbed(:notification_groups_subject, :certificate_name_type)])
    domain = notification_group.notification_groups_subjects.first.domain_name

    SslClient.any_instance.stubs(:retrieve_x509_cert).returns(create_x509_cert(domain))
    SslClient.any_instance.stubs(:verify_result).returns('certificate not trusted')

    notification_group.scan

    assert_equal ScanLog.count, 1
    assert_equal ScannedCertificate.count, 1
    assert ScanLog.last.scan_status == 'certificate not trusted'
    assert ScanLog.last.domain_name == notification_group.notification_groups_subjects.first.domain_name
    assert_equal ActionMailer::Base.deliveries.size, 1
    assert_equal Ahoy::Message.count, 1
  end

  xit 'scans domains associated with a notification groups succesfully (expired case)' do
    notification_group.stubs(:notification_groups_subjects).returns([build_stubbed(:notification_groups_subject, :certificate_name_type)])
    domain = notification_group.notification_groups_subjects.first.domain_name

    SslClient.any_instance.stubs(:retrieve_x509_cert).returns(create_x509_cert(domain))
    SslClient.any_instance.stubs(:verify_result).returns('certificate has expired')

    notification_group.scan

    assert_equal ScanLog.count, 1
    assert_equal ScannedCertificate.count, 1
    assert ScanLog.last.scan_status == 'certificate has expired'
    assert ScanLog.last.domain_name == notification_group.notification_groups_subjects.first.domain_name
    assert_equal ActionMailer::Base.deliveries.size, 1
    assert_equal Ahoy::Message.count, 1
  end

  xit 'scans domains associated with a notification groups succesfully (name_mismatch case)' do
    notification_group.stubs(:notification_groups_subjects).returns([build_stubbed(:notification_groups_subject, :certificate_name_type)])
    domain = notification_group.notification_groups_subjects.first.domain_name

    SslClient.any_instance.stubs(:retrieve_x509_cert).returns(create_x509_cert(domain))
    SslClient.any_instance.stubs(:verify_result).returns('subject issuer mismatch')

    notification_group.scan

    assert_equal ScanLog.count, 1
    assert_equal ScannedCertificate.count, 1
    assert ScanLog.last.scan_status == 'subject issuer mismatch'
    assert ScanLog.last.domain_name == notification_group.notification_groups_subjects.first.domain_name
    assert_equal ActionMailer::Base.deliveries.size, 1
    assert_equal Ahoy::Message.count, 1
  end
end
