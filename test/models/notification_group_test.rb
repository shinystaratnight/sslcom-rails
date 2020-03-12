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
#

require "test_helper"

describe NotificationGroup do
  include X509Helper

  before(:each) do
    ActionMailer::Base.deliveries.clear
    @notification_group = build_stubbed(:notification_group)
  end

  it "scans domains associated with a notification groups succesfully (success case: notification_group_subject)" do
    @notification_group.stubs(:notification_groups_subjects).returns([build_stubbed(:notification_groups_subject, :certificate_name_type)])
    domain = @notification_group.notification_groups_subjects.first.domain_name

    SslClient.any_instance.stubs(:retrieve_x509_cert).returns(create_x509_cert(domain))
    SslClient.any_instance.stubs(:verify_result).returns('ok')
    @notification_group.scan

    assert_equal ScannedCertificate.count, 1
    assert_equal ScanLog.count, 1
    assert ScanLog.last.scan_status == 'ok'
  end

  it "scans domains associated with a notification groups succesfully (success case: certificate_name)" do
    @notification_group.stubs(:certificate_names).returns([build_stubbed(:certificate_name)])
    domain = @notification_group.certificate_names.first.name

    SslClient.any_instance.stubs(:retrieve_x509_cert).returns(create_x509_cert(domain))
    SslClient.any_instance.stubs(:verify_result).returns('ok')
    @notification_group.scan

    assert_equal ScannedCertificate.count, 1
    assert_equal ScanLog.count, 1
    assert ScanLog.last.scan_status == 'ok'
  end

  it "scans domains associated with a notification groups succesfully (failure case)" do
    @notification_group.stubs(:notification_groups_subjects).returns([build_stubbed(:notification_groups_subject, :certificate_name_type)])
    domain = @notification_group.notification_groups_subjects.first.domain_name

    SslClient.any_instance.stubs(:retrieve_x509_cert).returns(nil)
    SslClient.any_instance.stubs(:verify_result).returns('not found')

    @notification_group.scan

    assert_equal ScannedCertificate.count, 0
    assert_equal ScanLog.count, 1
    assert ScanLog.last.scan_status == 'not found'
  end

  it "scans domains associated with a notification groups succesfully (untrusted case)" do
    @notification_group.stubs(:notification_groups_subjects).returns([build_stubbed(:notification_groups_subject, :certificate_name_type)])
    domain = @notification_group.notification_groups_subjects.first.domain_name

    SslClient.any_instance.stubs(:retrieve_x509_cert).returns(create_x509_cert(domain))
    SslClient.any_instance.stubs(:verify_result).returns('certificate not trusted')

    @notification_group.scan

    assert_equal ScanLog.count, 1
    assert_equal ScannedCertificate.count, 1
    assert ScanLog.last.scan_status == 'certificate not trusted'
    assert ScanLog.last.domain_name == @notification_group.notification_groups_subjects.first.domain_name
  end

  it "scans domains associated with a notification groups succesfully (expired case)" do
    @notification_group.stubs(:notification_groups_subjects).returns([build_stubbed(:notification_groups_subject, :certificate_name_type)])
    domain = @notification_group.notification_groups_subjects.first.domain_name

    SslClient.any_instance.stubs(:retrieve_x509_cert).returns(create_x509_cert(domain))
    SslClient.any_instance.stubs(:verify_result).returns('certificate has expired')

    @notification_group.scan

    assert_equal ScanLog.count, 1
    assert_equal ScannedCertificate.count, 1
    assert ScanLog.last.scan_status == 'certificate has expired'
    assert ScanLog.last.domain_name == @notification_group.notification_groups_subjects.first.domain_name
  end

  it "scans domains associated with a notification groups succesfully (name_mismatch case)" do
    @notification_group.stubs(:notification_groups_subjects).returns([build_stubbed(:notification_groups_subject, :certificate_name_type)])
    domain = @notification_group.notification_groups_subjects.first.domain_name

    SslClient.any_instance.stubs(:retrieve_x509_cert).returns(create_x509_cert(domain))
    SslClient.any_instance.stubs(:verify_result).returns('subject issuer mismatch')

    @notification_group.scan

    assert_equal ScanLog.count, 1
    assert_equal ScannedCertificate.count, 1
    assert ScanLog.last.scan_status == 'subject issuer mismatch'
    assert ScanLog.last.domain_name == @notification_group.notification_groups_subjects.first.domain_name
  end
end
