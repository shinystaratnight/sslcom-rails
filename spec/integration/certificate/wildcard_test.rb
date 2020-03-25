# require 'rails_helper'
# #
# # Workflow: user submits wildcard (single-domain | multi-subdomains) csr key.
# #
# describe 'wildcard (single-domain) csr' do
#   before do
#     initialize_roles
#     initialize_certificates
#     initialize_server_software
#     initialize_certificate_csr_keys
#     @logged_in_user     = create(:user, :owner)
#     @logged_in_ssl_acct = @logged_in_user.ssl_account
#     @logged_in_ssl_acct.billing_profiles << create(:billing_profile)
#     @year_3_id          = ProductVariantItem.find_by(serial:  "sslcomwc256ssl3yr").id
#     login_as(@logged_in_user, self.controller.cookies)
#
#     # Purchase wildcard certificate
#     # =========================================================
#     visit buy_certificate_path 'wildcard'
#     find("#product_variant_item_#{@year_3_id}").click # 3 Years $91.30/yr
#     find('#next_submit input').click # Shopping Cart
#     click_on 'Checkout'              # Checkout
#     find("#funding_source_#{BillingProfile.first.id}").click
#     find('input[name="next"]').click
#     sleep 2
#
#     cc         = CertificateContent.first
#     co         = CertificateOrder.first
#     validation = Validation.first
#     cart       = ShoppingCart.first
#     site_seal  = SiteSeal.first
#
#     assert_match 'new', validation.workflow_state
#     assert_match 'new', site_seal.workflow_state
#     assert_match 'new', cc.workflow_state
#     assert_match 'paid', co.workflow_state
#     assert_match 'paid', Order.first.state
#     assert_empty cc.signing_request
#     refute_nil   site_seal.id, co.site_seal_id
#     assert_nil   cc.signed_certificate
#     refute_nil   cc.ref
#     refute_nil   cc.label
#     refute_nil   cart.guid
#     assert_nil   cart.content
#     assert_equal 0, CertificateContact.count
#     assert_equal 0, ValidationRuling.count
#     assert_equal validation.id, co.validation_id
#     assert_equal SslAccount.first.id, co.ssl_account_id
#     assert_equal co.id, cc.certificate_order_id
#     assert_equal [], cc.domains
#
#     # Submit and validate CSR Key for non-wilrdcard certificate
#     # =========================================================
#     visit certificate_orders_path   # Certificate Orders
#     page.must_have_content('credit - wildcard certificate')
#
#     # Step 1: Submit CSR
#     click_on 'submit csr'
#     main_id = 'certificate_order_certificate_contents_attributes_0'
#     fill_in "#{main_id}_signing_request", with: @wildcard_csr.strip
#     select  'Oracle',                     from: "#{main_id}_server_software_id"
#     find('#next_submit').click
#
#     # Step 2: Registrant
#     page.must_have_content('*.rubricae.es')
#     registrant_id = 'certificate_order_certificate_contents_attributes_0_registrant_attributes'
#     fill_in "#{registrant_id}_company_name", with: 'EZOPS Inc'
#     fill_in "#{registrant_id}_address1",     with: '123 H St.'
#     fill_in "#{registrant_id}_city",         with: 'Houston'
#     fill_in "#{registrant_id}_state",        with: 'TX'
#     fill_in "#{registrant_id}_postal_code",  with: '12345'
#     find('input[alt="edit ssl certificate order"]').click
#
#     # Step 3: Contacts
#     contacts_id = 'certificate_content_certificate_contacts_attributes_0'
#     fill_in "#{contacts_id}_first_name", with: 'first'
#     fill_in "#{contacts_id}_last_name",  with: 'last'
#     fill_in "#{contacts_id}_email",      with: 'test_contact@domain.com'
#     fill_in "#{contacts_id}_phone",      with: '1233334444'
#     find('input[alt="Bl submit button"]').click
#   end
#
#   it 'creates correct records and renders correct information' do
#     sleep 2
#     cc  = CertificateContent.first
#     co  = CertificateOrder.first
#     csr = Csr.last
#
#     # creates database records
#     # =========================================================
#       assert_equal 1, Order.count
#       assert_equal 1, OrderTransaction.count
#       assert_equal 1, CertificateOrder.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 1, LineItem.count
#       assert_equal 1, OrderTransaction.count
#       assert_equal 1, ShoppingCart.count
#       assert_equal 4, CertificateContact.count
#       assert_equal 1, CertificateName.count
#       assert_equal 1, CaCertificateRequest.count
#       assert_equal 1, Validation.count
#       assert_equal 1, SiteSeal.count
#
#     # creates correct associations for CertificateContent and CertificateOrder
#     # =========================================================
#       assert_equal 1, cc.certificate_names.count
#       assert_equal 4, cc.certificate_contacts.count
#       refute_nil   cc.registrant
#       assert_equal 1, co.csrs.count
#       assert_equal 1, co.certificate_contents.count
#
#     # updates CertificateContent record
#     # =========================================================
#       assert_match 'pending_validation', cc.workflow_state
#       assert_match @wildcard_csr.strip.gsub("\n", "\r\n"), cc.signing_request
#       assert_match '*.rubricae.es', cc.certificate_names.first.name
#       refute_nil   cc.server_software_id
#
#     # creates correct Csr record
#     # =========================================================
#       assert_equal cc.id, csr.certificate_content_id
#       assert_equal 0, csr.signed_certificates.count
#       assert_equal 1, csr.ca_certificate_requests.count
#
#       assert_match '*.rubricae.es', csr.common_name
#       assert_match 'sha256WithRSAEncryption', csr.sig_alg
#       assert_match @wildcard_csr.strip.gsub("\n", "\r\n"), csr.body
#       refute_nil   csr.organization
#       refute_nil   csr.organization_unit
#       refute_nil   csr.state
#       refute_nil   csr.locality
#       refute_nil   csr.country
#       refute_nil   csr.email
#
#     # 'Domain Validation' page should have correct information
#     # =========================================================
#       page.must_have_content('Domain Validation')
#       page.must_have_content("Certificate Order ##{co.ref}")
#       page.must_have_content(cc.csr.common_name) # wildcard domain name
#   end
# end
