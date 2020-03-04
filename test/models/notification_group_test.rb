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

    ping_results = {certificate: create_x509_cert(domain, Time.now + 365.days), verify_result: 19}
    SslClient.any_instance.stubs(:ping_for_certificate_info).returns(ping_results)

    @notification_group.scan

    assert_equal ScannedCertificate.count, 1
    assert_equal ScanLog.count, 1
    assert ScanLog.last.scan_status == 'expiring'
  end

  it "scans domains associated with a notification groups succesfully (success case: certificate_name)" do
    @notification_group.stubs(:certificate_names).returns([build_stubbed(:certificate_name)])
    domain = @notification_group.certificate_names.first.name

    ping_results = {certificate: create_x509_cert(domain, Time.now + 365.days), verify_result: 19}
    SslClient.any_instance.stubs(:ping_for_certificate_info).returns(ping_results)

    @notification_group.scan

    assert_equal ScannedCertificate.count, 1
    assert_equal ScanLog.count, 1
    assert ScanLog.last.scan_status == 'expiring'
  end

  it "scans domains associated with a notification groups succesfully (failure case)" do
    @notification_group.stubs(:notification_groups_subjects).returns([build_stubbed(:notification_groups_subject, :certificate_name_type)])

    ping_results = {certificate: nil, verify_result: nil}
    SslClient.any_instance.stubs(:ping_for_certificate_info).returns(ping_results)

    @notification_group.scan

    assert_equal ScannedCertificate.count, 0
    assert_equal ScanLog.count, 1
    assert ScanLog.last.scan_status == 'not_found'
  end

  it "scans domains associated with a notification groups succesfully (untrusted case)" do
    @notification_group.stubs(:notification_groups_subjects).returns([build_stubbed(:notification_groups_subject, :certificate_name_type)])
    domain = @notification_group.notification_groups_subjects.first.domain_name

    ping_results = {certificate: create_x509_cert(domain, Time.now + 365.days), verify_result: 27}
    SslClient.any_instance.stubs(:ping_for_certificate_info).returns(ping_results)

    @notification_group.scan

    assert_equal ScanLog.count, 1
    assert_equal ScannedCertificate.count, 1
    assert ScanLog.last.scan_status == 'untrusted'
    assert ScanLog.last.domain_name == @notification_group.notification_groups_subjects.first.domain_name
  end

  it "scans domains associated with a notification groups succesfully (expired case)" do
    @notification_group.stubs(:notification_groups_subjects).returns([build_stubbed(:notification_groups_subject, :certificate_name_type)])
    domain = @notification_group.notification_groups_subjects.first.domain_name

    ping_results = {certificate: create_x509_cert(domain, Time.now), verify_result: 19}
    SslClient.any_instance.stubs(:ping_for_certificate_info).returns(ping_results)

    @notification_group.scan

    assert_equal ScanLog.count, 1
    assert_equal ScannedCertificate.count, 1
    assert ScanLog.last.scan_status == 'expired'
    assert ScanLog.last.domain_name == @notification_group.notification_groups_subjects.first.domain_name
  end

  it "scans domains associated with a notification groups succesfully (name_mismatch case)" do
    @notification_group.stubs(:notification_groups_subjects).returns([build_stubbed(:notification_groups_subject, :certificate_name_type)])
    domain = @notification_group.notification_groups_subjects.first.domain_name

    ping_results = {certificate: create_x509_cert(domain, Time.now + 365.days, true), verify_result: 19}
    SslClient.any_instance.stubs(:ping_for_certificate_info).returns(ping_results)

    @notification_group.scan

    assert_equal ScanLog.count, 1
    assert_equal ScannedCertificate.count, 1
    assert ScanLog.last.scan_status == 'name_mismatch'
    assert ScanLog.last.domain_name == @notification_group.notification_groups_subjects.first.domain_name
  end

  describe 'scan status change for certificates' do
    it 'sends a domain digest notice if a certificate changes status from one scan to the next' do
      @notification_group.stubs(:notification_groups_subjects).returns([build_stubbed(:notification_groups_subject, :certificate_name_type)])
      domain = @notification_group.notification_groups_subjects.first.domain_name
      x509_cert = create_x509_cert(domain, Time.now + 365.days)
      ping_results = {certificate: x509_cert, verify_result: 19}
      SslClient.any_instance.stubs(:ping_for_certificate_info).returns(ping_results)

      @notification_group.scan

      assert_equal ScannedCertificate.count, 1
      assert_equal ScanLog.count, 1
      assert ScanLog.last.scan_status == 'expiring'

      ping_results_two = {certificate: x509_cert, verify_result: 27}
      SslClient.any_instance.stubs(:ping_for_certificate_info).returns(ping_results_two)

      @notification_group.scan
      
      assert_equal ScannedCertificate.count, 1
      assert_equal ScanLog.count, 2
      assert ScanLog.last.scan_status == 'untrusted'
      assert_equal ActionMailer::Base.deliveries.size, 1
      assert_equal Ahoy::Message.count, 1
    end
  end
end
