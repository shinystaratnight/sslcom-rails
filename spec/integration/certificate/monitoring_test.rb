# require 'rails_helper'
# require 'rake'
#
# describe 'monitoring' do
#   before :all do
#     initialize_roles
#     initialize_certificates
#     initialize_server_software
#     initialize_certificate_csr_keys
#
#     @logged_in_user = create(:user, :owner)
#     @logged_in_ssl_acct = @logged_in_user.ssl_account
#     @logged_in_ssl_acct.billing_profiles << create(:billing_profile)
#
#     login_as(@logged_in_user, self.controller.cookies)
#
#     @main_id = 'certificate_order_certificate_contents_attributes_0'
#     @first_domains_group = 'browsec.com ncentral.itassist.ro ex.tzk.ru'
#     @second_domains_group =
#         'api4.sunnyweatherdom.com api5.sunnyweatherdom.com api6.sunnyweatherdom.com api7.sunnyweatherdom.com api8.sunnyweatherdom.com api9.sunnyweatherdom.com'
#
#     # Load tasks
#     SslCom::Application.load_tasks if Rake::Task.tasks.empty?
#     # Rake.application.rake_require "lib/tasks/scan"
#     Rake::Task.define_task(:environment)
#   end
#
#   describe 'test rake task' do
#     let :run_rake_task do
#       Rake::Task['scan:scan_and_reminder_expiring_domains'].reenable
#       Rake.application.invoke_task 'scan:scan_and_reminder_expiring_domains'
#     end
#
#     it 'scan 3 domains, scan 3 certificates and sent one reminder for notification group' do
#       # ====================== Purchase UCC Certificate w/3 domains ======================
#       # Visit /certificates/evucc/buy page
#       visit buy_certificate_path "evucc"
#
#       # Choose 2 Year for Duration
#       find("#certificate_order_duration_1").click
#
#       # Add domains
#       fill_in "#{@main_id}_additional_domains", with: @first_domains_group
#
#       # Form Submit
#       page.execute_script("jQuery('form').submit();")
#
#       # Check Whether Shopping cart page has been opened or not
#       @first_domains_group.split.each {|domain| page.must_have_content domain}
#
#       # To Checkout Page
#       click_on "Checkout"
#
#       # Choosing Payment method
#       find("#funding_source_#{BillingProfile.first.id}").click
#
#       # Checkout
#       find('input[name="next"]').click
#       sleep 2
#
#       # ====================== Purchase and submit CSR Key for non-wilrdcard certificate ======================
#       # Get Certificate Content
#       cc = CertificateContent.first
#
#       # Visit Certificate Order's search page.
#       visit certificate_orders_path   # Certificate Orders
#
#       # Check Certificate order list page has been opened or not.
#       page.must_have_content("credit - enterprise ev ucc cer")
#
#       # Go to Submit CSR Page.
#       click_on "submit csr"           # Step 1: Submit CSR
#
#       # Fill in CSR field.
#       fill_in "#{@main_id}_signing_request", with: @nonwildcard_csr.strip
#
#       # Select one for server software
#       select  "Oracle", from: "#{@main_id}_server_software_id"
#
#       # Click submit button for next.
#       find("#next_submit").click
#
#       # For Registrant for Certificate Order
#       fill_in_cert_registrant         # Step 2: Registrant
#
#       # For Contact for Certificate Order
#       fill_in_cert_contacts           # Step 3: Contacts
#
#       # Issue Certificate
#       issue_certificate(Csr.find_by(certificate_content_id: cc.id).id)
#
#       # Visit Notification Group Page
#       visit notification_groups_path
#
#       # Open Notification Group
#       ng = NotificationGroup.first
#       click_on ng.friendly_name
#
#       # Choose Custom Schedule Type
#       find("#schedule_type_false").click
#
#       # Save Notification Group
#       find(".save_notification_group").click
#       page.must_have_content("Notification Groups Management")
#
#       # Call Scan.rake file
#       run_rake_task
#
#       # Compare Scan Logs count
#       scan_logs_counts = ScanLog.count
#       assert_equal 3, scan_logs_counts
#
#       # Compare Scanned Certificate Count
#       scanned_cert_counts = ScannedCertificate.count
#       assert_equal 3, scanned_cert_counts
#
#       # Compare Sent Reminder Count
#       sent_reminder_count = SentReminder.count
#       assert_equal 1, sent_reminder_count
#
#       # Compare Sent Email Address
#       sent_reminder = SentReminder.first
#       assert_equal @logged_in_user.email, sent_reminder.recipients
#     end
#
#     it 'It should scan 6 domains, scan 0 certificate and not reminder for notification group' do
#       # ====================== Purchase UCC Certificate w/3 domains ======================
#       # Visit /certificates/evucc/buy page
#       visit buy_certificate_path "evucc"
#
#       # Choose 2 Year for Duration
#       find("#certificate_order_duration_2").click
#
#       # Add domains
#       fill_in "#{@main_id}_additional_domains", with: @second_domains_group
#
#       # Form Submit
#       page.execute_script("jQuery('form').submit();")
#
#       # Check Whether Shopping cart page has been opened or not
#       @second_domains_group.split.each {|domain| page.must_have_content domain}
#
#       # To Checkout Page
#       click_on "Checkout"
#
#       # Choosing Payment method
#       find("#funding_source_#{BillingProfile.first.id}").click
#
#       # Checkout
#       find('input[name="next"]').click
#       sleep 2
#
#       # ====================== Purchase and submit CSR Key for non-wilrdcard certificate ======================
#       # Get Certificate Content
#       cc = CertificateContent.first
#
#       # Visit Certificate Order's search page.
#       visit certificate_orders_path   # Certificate Orders
#
#       # Check Certificate order list page has been opened or not.
#       page.must_have_content("credit - enterprise ev ucc cer")
#
#       # Go to Submit CSR Page.
#       click_on "submit csr"           # Step 1: Submit CSR
#
#       # Fill in CSR field.
#       fill_in "#{@main_id}_signing_request", with: @nonwildcard_csr.strip
#
#       # Select one for server software
#       select  "Oracle", from: "#{@main_id}_server_software_id"
#
#       # Click submit button for next.
#       find("#next_submit").click
#
#       # For Registrant for Certificate Order
#       fill_in_cert_registrant         # Step 2: Registrant
#
#       # For Contact for Certificate Order
#       fill_in_cert_contacts           # Step 3: Contacts
#
#       # Issue Certificate
#       issue_certificate(Csr.find_by(certificate_content_id: cc.id).id)
#
#       # Visit Notification Group Page
#       visit notification_groups_path
#
#       # Open Notification Group
#       ng = NotificationGroup.first
#       click_on ng.friendly_name
#
#       # Choose Custom Schedule Type
#       find("#schedule_type_false").click
#
#       # Save Notification Group
#       find(".save_notification_group").click
#       page.must_have_content("Notification Groups Management")
#
#       # Call Scan.rake file
#       run_rake_task
#
#       # Compare Scan Logs count
#       scan_logs_counts = ScanLog.count
#       assert_equal 6, scan_logs_counts
#
#       # Compare Scanned Certificate Count
#       scanned_cert_counts = ScannedCertificate.count
#       assert_equal 0, scanned_cert_counts
#
#       # Compare Sent Reminder Count
#       sent_reminder_count = SentReminder.count
#       assert_equal 0, sent_reminder_count
#     end
#   end
# end
