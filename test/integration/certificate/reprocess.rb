# require 'rails_helper'
# #
# # Workflow: Reprocess certificate after it has been issued.
# #
# describe 'reprocess' do
#   before do
#     initialize_roles
#     initialize_certificates
#     initialize_server_software
#     initialize_certificate_csr_keys
#     @logged_in_user     = create(:user, :owner)
#     @logged_in_ssl_acct = @logged_in_user.ssl_account
#     @logged_in_ssl_acct.billing_profiles << create(:billing_profile)
#     login_as(@logged_in_user, self.controller.cookies)
#     @main_id = 'certificate_order_certificate_contents_attributes_0'
#     @domains = 'sunnyweatherdom1.com sunnyweatherdom2.com sunnyweatherdom3.com'
#
#     # Purchase UCC certificate w/3 domains
#     # =========================================================
#     visit buy_certificate_path "evucc"
#     find("#certificate_order_duration_2").click              # 2 Years
#     fill_in "#{@main_id}_additional_domains", with: @domains # Domains
#     find("#next_submit input").click                         # Shopping Cart
#     @domains.split.each {|d| page.must_have_content d}
#     click_on "Checkout"                                      # Checkout
#     find("#funding_source_#{BillingProfile.first.id}").click
#     find('input[name="next"]').click
#     sleep 2
#
#     # Purchase and submit CSR Key for non-wilrdcard certificate
#     # =========================================================
#     cc = CertificateContent.first
#     visit certificate_orders_path   # Certificate Orders
#     page.must_have_content("credit - enterprise ev ucc cer")
#     click_on "submit csr"           # Step 1: Submit CSR
#     fill_in "#{@main_id}_signing_request", with: @nonwildcard_csr.strip
#     select  "Oracle", from: "#{@main_id}_server_software_id"
#     find("#next_submit").click
#     fill_in_cert_registrant         # Step 2: Registrant
#     fill_in_cert_contacts           # Step 3: Contacts
#     issue_certificate(Csr.find_by(certificate_content_id: cc.id).id)
#     assert_equal 3, cc.domains.count
#   end
#
#   it 'can reprocess issued certificate' do
#     # Reprocess and issue certificate
#     # =========================================================
#     new_domains = "sunnyweatherdom3.com sunnyweatherdom4.com"
#     new_domains_arr = new_domains.split.sort
#     rekey_certificate new_domains
#     issue_certificate(
#       Csr.find_by(certificate_content_id: get_last_certificate_content.id).id
#     )
#     visit certificate_orders_path
#
#     # creates database records
#     # =========================================================
#       cc = CertificateContent.last
#       sc = SignedCertificate.last
#
#       # Certificate Content (issued)
#       assert_equal 2, CertificateContent.count
#       assert_equal 2, cc.domains.count
#       assert_equal new_domains_arr, cc.domains.sort
#       assert_match "issued", cc.workflow_state
#       assert_match "#{cc.certificate_order.ref}-1", cc.label
#       assert_match "#{cc.certificate_order.ref}-1", cc.ref
#       refute_nil cc.signing_request
#
#       # Signed Certificate
#       assert_equal 2, SignedCertificate.count
#       assert_match "issued", sc.status
#       assert_match Settings.portal_domain, sc.common_name
#       refute_nil sc.organization
#       refute_nil sc.organization_unit
#       refute_nil sc.address1
#       refute_nil sc.locality
#       refute_nil sc.state
#       refute_nil sc.postal_code
#       refute_nil sc.country
#       refute_nil sc.fingerprintSHA
#       refute_nil sc.fingerprint
#       refute_nil sc.signature
#       refute_nil sc.subject_alternative_names
#       refute_nil sc.strength
#       refute_nil sc.decoded
#       refute_nil sc.body
#
#       # Certificate Names (2 total after reprocess)
#       cert_names = cc.certificate_names
#       assert_equal 2, cert_names.count
#       assert_equal new_domains_arr, cert_names.map(&:name).sort
#
#       # CaApiRequest
#       reprocess_request = CaApiRequest.where(api_requestable_id: Csr.last.id, api_requestable_type: 'Csr')
#       reprocess_params  = reprocess_request.first.parameters
#       assert_equal 6, CaApiRequest.count
#       assert_equal 1, reprocess_request.count
#       new_domains_arr.each{|domain| assert_includes reprocess_params, domain}
#   end
#
#   it 'reprocesses w/400+ domains and subdomains' do
#     # Reprocess and issue certificate
#     new_domains = "sunnyweatherdomain0.com"
#     (1..400).each{|n| new_domains << " sunnyweatherdomain#{n}.com"}
#     new_domains_arr = new_domains.split.sort
#     rekey_certificate new_domains
#     issue_certificate(
#       Csr.find_by(certificate_content_id: get_last_certificate_content.id).id
#     )
#     reprocess_params  = CaApiRequest.where(
#       api_requestable_id: Csr.last.id,
#       api_requestable_type: 'Csr'
#     ).first.parameters
#     cc = get_last_certificate_content
#
#     # All 401 domains are included to Comodo API AutoReplaceSSL request
#     new_domains_arr.each{|domain| assert_includes reprocess_params, domain}
#
#     # Certificate Names (401 total after reprocess)
#     assert_equal 401, cc.certificate_names.count
#     assert_equal new_domains_arr, cc.certificate_names.map(&:name).sort
#   end
#
#   it 'ignores duplicate domains' do
#     # Reprocess and issue certificate w/6 domains 3 duplicates (w/mixed case letters)
#     new_domains = @domains + " SunnyWeatherdom1.com SunnyWeatherdom2.com SUNNYWeatherdom3.com"
#     new_domains_arr = new_domains.split.map(&:downcase).sort.uniq
#     rekey_certificate new_domains
#     issue_certificate(
#       Csr.find_by(certificate_content_id: get_last_certificate_content.id).id
#     )
#     reprocess_params  = CaApiRequest.where(
#       api_requestable_id: Csr.last.id,
#       api_requestable_type: 'Csr'
#     ).first.parameters
#     cc = get_last_certificate_content
#
#     # Only 3 domains are included to Comodo API AutoReplaceSSL request
#     new_domains_arr.each{|domain| assert_includes reprocess_params, domain}
#
#     # Certificate Names (3 total after reprocess)
#     assert_equal 3, cc.certificate_names.count
#     assert_equal new_domains_arr, cc.certificate_names.map(&:name).sort
#   end
# end
