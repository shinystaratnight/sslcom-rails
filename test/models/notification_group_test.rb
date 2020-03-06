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

    ping_results = {certificate: create_x509_cert(domain), verify_result: 'ok'}
    SslClient.any_instance.stubs(:ping_for_certificate_info).returns(ping_results)

    @notification_group.scan

    assert_equal ScannedCertificate.count, 1
    assert_equal ScanLog.count, 1
    assert ScanLog.last.scan_status == 'ok'
  end

  it "scans domains associated with a notification groups succesfully (success case: certificate_name)" do
    @notification_group.stubs(:certificate_names).returns([build_stubbed(:certificate_name)])
    domain = @notification_group.certificate_names.first.name

    ping_results = {certificate: create_x509_cert(domain), verify_result: 'ok'}
    SslClient.any_instance.stubs(:ping_for_certificate_info).returns(ping_results)

    @notification_group.scan

    assert_equal ScannedCertificate.count, 1
    assert_equal ScanLog.count, 1
    assert ScanLog.last.scan_status == 'ok'
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

    ping_results = {certificate: create_x509_cert(domain), verify_result: 'certificate not trusted'}
    SslClient.any_instance.stubs(:ping_for_certificate_info).returns(ping_results)

    @notification_group.scan

    assert_equal ScanLog.count, 1
    assert_equal ScannedCertificate.count, 1
    assert ScanLog.last.scan_status == 'certificate not trusted'
    assert ScanLog.last.domain_name == @notification_group.notification_groups_subjects.first.domain_name
  end

  it "scans domains associated with a notification groups succesfully (expired case)" do
    @notification_group.stubs(:notification_groups_subjects).returns([build_stubbed(:notification_groups_subject, :certificate_name_type)])
    domain = @notification_group.notification_groups_subjects.first.domain_name

    ping_results = {certificate: create_x509_cert(domain), verify_result: 'certificate has expired'}
    SslClient.any_instance.stubs(:ping_for_certificate_info).returns(ping_results)

    @notification_group.scan

    assert_equal ScanLog.count, 1
    assert_equal ScannedCertificate.count, 1
    assert ScanLog.last.scan_status == 'certificate has expired'
    assert ScanLog.last.domain_name == @notification_group.notification_groups_subjects.first.domain_name
  end

  it "scans domains associated with a notification groups succesfully (name_mismatch case)" do
    @notification_group.stubs(:notification_groups_subjects).returns([build_stubbed(:notification_groups_subject, :certificate_name_type)])
    domain = @notification_group.notification_groups_subjects.first.domain_name

    ping_results = {certificate: create_x509_cert(domain), verify_result: 'subject issuer mismatch'}
    SslClient.any_instance.stubs(:ping_for_certificate_info).returns(ping_results)

    @notification_group.scan

    assert_equal ScanLog.count, 1
    assert_equal ScannedCertificate.count, 1
    assert ScanLog.last.scan_status == 'subject issuer mismatch'
    assert ScanLog.last.domain_name == @notification_group.notification_groups_subjects.first.domain_name
  end

  describe 'scan status change for certificates' do
    it 'sends a domain digest notice if a certificate changes status from one scan to the next' do
      @notification_group.stubs(:notification_groups_subjects).returns([build_stubbed(:notification_groups_subject, :certificate_name_type)])
      domain = @notification_group.notification_groups_subjects.first.domain_name
      x509_cert = create_x509_cert(domain)
      ping_results = {certificate: x509_cert, verify_result: 'ok'}
      SslClient.any_instance.stubs(:ping_for_certificate_info).returns(ping_results)

      @notification_group.scan

      assert_equal ScannedCertificate.count, 1
      assert_equal ScanLog.count, 1
      assert ScanLog.last.scan_status == 'ok'

      ping_results_two = {certificate: x509_cert, verify_result: 'certificate not trusted'}
      SslClient.any_instance.stubs(:ping_for_certificate_info).returns(ping_results_two)

      @notification_group.scan

      assert_equal ScannedCertificate.count, 1
      assert_equal ScanLog.count, 2
      assert ScanLog.last.scan_status == 'certificate not trusted'
      assert_equal ActionMailer::Base.deliveries.size, 1
      assert_equal Ahoy::Message.count, 1
    end
  end
end
