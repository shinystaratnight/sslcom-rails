# require 'rails_helper'
#
# describe 'email notification' do
#   before do
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
#     @first_domains_group = 'api1.sunnyweatherdom.com api2.sunnyweatherdom.com api3.sunnyweatherdom.com'
#     @second_domains_group =
#         'api4.sunnyweatherdom.com api5.sunnyweatherdom.com api6.sunnyweatherdom.com api7.sunnyweatherdom.com api8.sunnyweatherdom.com api9.sunnyweatherdom.com'
#   end
#
#   it 'send one email notification' do
#     # ====================== Purchase UCC Certificate w/3 domains ======================
#     # Visit /certificates/evucc/buy page
#     visit buy_certificate_path "evucc"
#
#     # Choose 2 Year for Duration
#     find("#certificate_order_duration_2").click
#
#     # Add domains
#     fill_in "#{@main_id}_additional_domains", with: @first_domains_group
#
#     # Form Submit
#     page.execute_script("jQuery('form').submit();")
#
#     # Check Whether Shopping cart page has been opened or not
#     @first_domains_group.split.each {|domain| page.must_have_content domain}
#
#     # To Checkout Page
#     click_on "Checkout"
#
#     # Choosing Payment method
#     find("#funding_source_#{BillingProfile.first.id}").click
#
#     # Checkout
#     find('input[name="next"]').click
#     sleep 2
#
#     # ====================== Purchase and submit CSR Key for non-wilrdcard certificate ======================
#     # Get Certificate Content
#     cc = CertificateContent.first
#
#     # Visit Certificate Order's search page.
#     visit certificate_orders_path   # Certificate Orders
#
#     # Check Certificate order list page has been opened or not.
#     page.must_have_content("credit - enterprise ev ucc cer")
#
#     # Go to Submit CSR Page.
#     click_on "submit csr"           # Step 1: Submit CSR
#     fill_in "#{@main_id}_signing_request", with: @nonwildcard_csr.strip
#     select  "Oracle", from: "#{@main_id}_server_software_id"
#     find("#next_submit").click
#
#     # For Registrant for Certificate Order
#     fill_in_cert_registrant         # Step 2: Registrant
#
#     # For Contact for Certificate Order
#     fill_in_cert_contacts           # Step 3: Contacts
#
#     # Issue Certificate
#     issue_certificate(Csr.find_by(certificate_content_id: cc.id).id)
#
#     # Check Domains
#     assert_equal 3, cc.domains.count
#
#     # Send reminder
#     SslAccount.unscoped.order('created_at').find_each do |ssl_acct|
#       # Get old expiring certificates
#       e_certs = ssl_acct.expiring_certificates_for_old
#
#       # Send notification for old expiring certificates
#       digest = {}
#       SslAccount.send_notify(e_certs, digest)
#     end
#
#     # Get Sent Reminder
#     sr_count = SentReminder.count
#     assert_equal 1, sr_count
#   end
#
#   it 'no send email notification' do
#     # ====================== Purchase UCC Certificate w/3 domains ======================
#     # Visit /certificates/evucc/buy page
#     visit buy_certificate_path "evucc"
#
#     # Choose 1 Year for Duration
#     find("#certificate_order_duration_1").click
#
#     # Add domains
#     fill_in "#{@main_id}_additional_domains", with: @second_domains_group
#
#     # Form Submit
#     page.execute_script("jQuery('form').submit();")
#
#     # Check Whether Shopping cart page has been opened or not
#     @second_domains_group.split.each {|domain| page.must_have_content domain}
#
#     # To Checkout Page
#     click_on "Checkout"
#
#     # Choosing Payment method
#     find("#funding_source_#{BillingProfile.first.id}").click
#
#     # Checkout
#     find('input[name="next"]').click
#     sleep 2
#
#     # ====================== Purchase and submit CSR Key for non-wilrdcard certificate ======================
#     # Get Certificate Content
#     cc = CertificateContent.first
#
#     # Visit Certificate Order's search page.
#     visit certificate_orders_path   # Certificate Orders
#
#     # Check Certificate order list page has been opened or not.
#     page.must_have_content("credit - enterprise ev ucc cer")
#
#     # Go to Submit CSR Page.
#     click_on "submit csr"           # Step 1: Submit CSR
#     fill_in "#{@main_id}_signing_request", with: @nonwildcard_csr.strip
#     select  "Oracle", from: "#{@main_id}_server_software_id"
#     find("#next_submit").click
#
#     # For Registrant for Certificate Order
#     fill_in_cert_registrant         # Step 2: Registrant
#
#     # For Contact for Certificate Order
#     fill_in_cert_contacts           # Step 3: Contacts
#
#     # Issue Certificate
#     issue_certificate(Csr.find_by(certificate_content_id: cc.id).id)
#
#     # Check Domains
#     assert_equal 6, cc.domains.count
#
#     # Send reminder
#     SslAccount.unscoped.order('created_at').find_each do |ssl_acct|
#       # Get old expiring certificates
#       e_certs = ssl_acct.expiring_certificates_for_old
#
#       # Send notification for old expiring certificates
#       digest = {}
#       SslAccount.send_notify(e_certs, digest)
#     end
#
#     # Get Sent Reminder
#     sr_count = SentReminder.count
#     assert_equal 0, sr_count
#   end
# end
