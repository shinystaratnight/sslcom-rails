# require 'rails_helper'
#
# class CertCreateWithBillingTest < ActionDispatch::IntegrationTest
#   # POST /certificates
#   #   IF billing profile (last_digits) is provided, then attempt to charge
#   #   the stored credit card. If declined, return billing_profile error.
#   #   IF billing profile is NOT provided, charge the funded account. Return
#   #   funded account error if insufficient funds.
#
#   describe 'create_v1_4' do
#     before do
#       api_main_setup
#       @team.funded_account.update(cents: 100000)
#       @team.billing_profiles << create(:billing_profile)
#       @team.billing_profiles << create(:billing_profile, :declined)
#       @billing_profile = @team.billing_profiles.first
#       @billing_profile_invalid = @team.billing_profiles.last
#       assert_equal 0, InvalidApiCertificateRequest.count
#       assert_equal 2, BillingProfile.count
#       @req = api_get_request_for_evucc
#         .merge(api_get_server_software)
#         .merge(api_get_csr_registrant)
#         .merge(api_get_csr_contacts)
#     end
#     # Params:       domains hash (5)
#     #               billing_profile
#     #
#     # Should:       save domains from array in CertificateContent, 5 total
#     #               charge for all 7 domains, 3 @ $133 and 2 @ $129
#     #               charge goes on the billing profile
#     #
#     # Should NOT:   charge the funded account
#     # ==========================================================================
#     it 'status 200: VALID billing_profile' do
#       post api_certificate_create_v1_4_path(@req
#         .merge(domains: (1..5).to_a.map {|n| "ssltestdomain#{n}.com"})
#         .merge(billing_profile: @billing_profile.last_digits)
#       )
#       items = JSON.parse(body)
#
#       # response
#       assert       match_response_schema('cert_create_voucher')
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 10, items.count
#       assert_match 'unused. waiting on certificate signing request (csr) from customer', items['order_status']
#       assert_equal '$657.00', items['order_amount'] # 3 domains * $133.00 AND 2 domains * $129.00
#       refute_nil   items['ref']
#       refute_nil   items['certificate_url']
#       refute_nil   items['receipt_url']
#       refute_nil   items['smart_seal_url']
#       refute_nil   items['validation_url']
#       assert_nil   items['registrant']
#       assert_nil   items['validations']
#       assert_nil   items['external_order_number']
#
#       # db records
#       assert_equal 1, CaApiRequest.count
#       assert_equal 1, Order.count
#       assert_equal 1, OrderTransaction.count
#       assert_equal 1, Validation.count
#       assert_equal 1, SiteSeal.count
#       assert_equal 1, CertificateOrder.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 3, SubOrderItem.count
#       assert_equal 1, LineItem.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 5, CertificateContent.last.domains.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#
#       # Funded Account is NOT deducted for the amount $657.00
#       assert_equal 100000, FundedAccount.last.cents
#
#       # Order
#       o = Order.first
#       assert_equal 65700, o.cents
#       assert_equal @team.id, o.billable_id
#       assert_match 'paid', o.state
#       assert_match 'SslAccount', o.billable_type
#
#       # OrderTransaction
#       ot = o.order_transactions.first
#       assert_equal 657, ot.amount
#       assert_match 'This transaction has been approved', ot.message
#       assert_match 'purchase', ot.action
#       assert_match 'pass', ot.cvv
#       refute_nil   ot.params
#       refute_nil   ot.reference
#       assert       ot.success
#     end
#     # Params:       domains hash (5)
#     # NO params:    billing_profile
#     # Should:       save domains from array in CertificateContent, 5 total
#     #               charge for all 7 domains, 3 @ $133 and 2 @ $129
#     #               charge goes on the funded account
#     #
#     # Should NOT:   charge the billing profile
#     # ==========================================================================
#     it 'status 200: NO billing_profile, charge funded_account' do
#
#       post api_certificate_create_v1_4_path(@req
#         .merge(domains: (1..5).to_a.map {|n| "ssltestdomain#{n}.com"})
#       )
#       items = JSON.parse(body)
#
#       # response
#       assert       match_response_schema('cert_create_voucher')
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 10, items.count
#       assert_match 'unused. waiting on certificate signing request (csr) from customer', items['order_status']
#       assert_equal '$657.00', items['order_amount'] # 3 domains * $133.00 AND 2 domains * $129.00
#       refute_nil   items['ref']
#       refute_nil   items['certificate_url']
#       refute_nil   items['receipt_url']
#       refute_nil   items['smart_seal_url']
#       refute_nil   items['validation_url']
#       assert_nil   items['registrant']
#       assert_nil   items['validations']
#       assert_nil   items['external_order_number']
#
#       # db records
#       assert_equal 1, CaApiRequest.count
#       assert_equal 1, Order.count
#       assert_equal 1, Validation.count
#       assert_equal 1, SiteSeal.count
#       assert_equal 1, CertificateOrder.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 3, SubOrderItem.count
#       assert_equal 1, LineItem.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 5, CertificateContent.last.domains.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#
#       # Funded Account is deducted for the amount $657.00
#       assert_equal (100000 - 65700), FundedAccount.last.cents
#
#       # Order
#       o = Order.first
#       assert_equal 65700, o.cents
#       assert_equal @team.id, o.billable_id
#       assert_match 'paid', o.state
#       assert_match 'SslAccount', o.billable_type
#
#       # OrderTransaction - credit card was not charged
#       assert_equal 0, OrderTransaction.count
#     end
#     # Params:       domains hash (5)
#     #               billing_profile (card declined)
#     #
#     # Should:       save domains from array in CertificateContent, 5 total
#     #               charge for all 7 domains, 3 @ $133 and 2 @ $129
#     #
#     # Should NOT:   charge the funded account
#     #               charge the billing profile
#     # ==========================================================================
#     it 'status 200: DECLINED billing_profile' do
#       post api_certificate_create_v1_4_path(@req
#         .merge(domains: (1..5).to_a.map {|n| "ssltestdomain#{n}.com"})
#         .merge(billing_profile: @billing_profile_invalid.last_digits)
#       )
#       items = JSON.parse(body)
#
#       # response
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 1, items.count
#       refute_nil   items['errors']
#       assert_match 'This transaction has been declined.', items['errors']['billing_profile'].first
#
#       # db records
#       assert_equal 1, CaApiRequest.count
#       assert_equal 0, CaDcvRequest.count
#       assert_equal 0, Registrant.count
#       assert_equal 1, Validation.count
#       assert_equal 1, SiteSeal.count
#       assert_equal 1, CertificateOrder.count
#       assert_equal 0, CertificateContact.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 0, SignedCertificate.count
#       assert_equal 3, SubOrderItem.count
#       assert_equal 1, LineItem.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#
#       # Funded Account is NOT deducted for the amount $657.00
#       assert_equal 100000, FundedAccount.last.cents
#
#       # Order - payment_declined
#       o = Order.unscoped.first
#       assert_equal 1, Order.unscoped.count
#       assert_equal 65700, o.cents
#       assert_equal @team.id, o.billable_id
#       assert_match 'payment_declined', o.state
#       assert_match 'SslAccount', o.billable_type
#
#       # OrderTransaction - declined
#       ot = o.order_transactions.first
#       assert_equal 1, OrderTransaction.count
#       assert_equal 657, ot.amount
#       assert_match 'This transaction has been declined.', ot.message
#       assert_match 'purchase', ot.action
#       assert_nil   ot.cvv
#       assert_nil   ot.reference
#       refute_nil   ot.params
#       refute       ot.success
#     end
#     # Params:       domains hash (5)
#     #               billing_profile (card declined)
#     #
#     # Should:       save domains from array in CertificateContent, 5 total
#     #               charge for all 7 domains, 3 @ $133 and 2 @ $129
#     #
#     # Should NOT:   charge the funded account
#     #               charge the billing profile
#     # ==========================================================================
#     it 'status 200: INVALID funded_account' do
#       @team.funded_account.update(cents: 50000)
#
#       post api_certificate_create_v1_4_path(@req
#         .merge(domains: (1..5).to_a.map {|n| "ssltestdomain#{n}.com"})
#       )
#       items = JSON.parse(body)
#
#       # response
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 1, items.count
#       refute_nil   items['errors']
#       assert_includes items['errors']['funded_account'].first, 'Please deposit additional $157.00.'
#
#       # db records
#       assert_equal 1, CaApiRequest.count
#       assert_equal 0, CaDcvRequest.count
#       assert_equal 0, Registrant.count
#       assert_equal 0, Validation.count
#       assert_equal 0, SiteSeal.count
#       assert_equal 0, CertificateOrder.count
#       assert_equal 0, CertificateContact.count
#       assert_equal 0, CertificateContent.count
#       assert_equal 0, SignedCertificate.count
#       assert_equal 0, SubOrderItem.count
#       assert_equal 0, LineItem.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#
#       # Funded Account still has the initial amount of $500.00
#       assert_equal 50000, FundedAccount.last.cents
#
#       # Order
#       assert_equal 0, Order.unscoped.count
#
#       # OrderTransaction - declined
#       assert_equal 0, OrderTransaction.count
#     end
#
#     # Params:       domains hash (w/dvc)
#     # Should:       save 1 domain in CertificateContent, 1 total
#     #               order should be $0
#     # Should NOT:   charge the funded account
#     #               charge the billing profile
#     # ==========================================================================
#     it 'status 200: Free SSL, no charge' do
#       req = api_get_request_for_free
#         .merge(api_get_server_software)
#         .merge(api_get_csr_registrant)
#         .merge(api_get_csr_contacts)
#
#       post api_certificate_create_v1_4_path(req
#         .merge(domains: {'www.ssltestdomain2.com':  {dcv: 'admin@ssltestdomain2.com'}})
#       )
#       items = JSON.parse(body)
#
#       # response
#       assert       match_response_schema('cert_create_voucher')
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 10, items.count
#       assert_match 'unused. waiting on certificate signing request (csr) from customer', items['order_status']
#       assert_equal '$0.00', items['order_amount']
#       refute_nil   items['ref']
#       refute_nil   items['certificate_url']
#       refute_nil   items['receipt_url']
#       refute_nil   items['smart_seal_url']
#       refute_nil   items['validation_url']
#       assert_nil   items['registrant']
#       assert_nil   items['validations']
#       assert_nil   items['external_order_number']
#
#       # db records
#       assert_equal 1, CaApiRequest.count
#       assert_equal 1, Order.count
#       assert_equal 1, Validation.count
#       assert_equal 1, SiteSeal.count
#       assert_equal 1, CertificateOrder.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 1, SubOrderItem.count
#       assert_equal 1, LineItem.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 1, CertificateContent.last.domains.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#
#       # Funded Account is NOT charged
#       assert_equal 100000, FundedAccount.last.cents
#
#       # Order is paid
#       o = Order.first
#       assert_equal 0, o.cents
#       assert_equal @team.id, o.billable_id
#       assert_match 'paid', o.state
#       assert_match 'SslAccount', o.billable_type
#
#       # OrderTransaction - credit card was not charged
#       assert_equal 0, OrderTransaction.count
#     end
#
#     # Params:       domains hash (w/dvc)
#     #               billing_profile
#     # Should:       save 1 domain in CertificateContent, 1 total
#     #               order should be $0
#     # Should NOT:   charge the funded account
#     #               charge the billing profile
#     # ==========================================================================
#     it 'status 200: Free SSL w/billing_profile, no charge' do
#       req = api_get_request_for_free
#         .merge(api_get_server_software)
#         .merge(api_get_csr_registrant)
#         .merge(api_get_csr_contacts)
#
#       post api_certificate_create_v1_4_path(req
#         .merge(domains: {'www.ssltestdomain2.com':  {dcv: 'admin@ssltestdomain2.com'}})
#         .merge(billing_profile: @billing_profile.last_digits)
#       )
#       items = JSON.parse(body)
#
#       # response
#       assert       match_response_schema('cert_create_voucher')
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 10, items.count
#       assert_match 'unused. waiting on certificate signing request (csr) from customer', items['order_status']
#       assert_equal '$0.00', items['order_amount']
#       refute_nil   items['ref']
#       refute_nil   items['certificate_url']
#       refute_nil   items['receipt_url']
#       refute_nil   items['smart_seal_url']
#       refute_nil   items['validation_url']
#       assert_nil   items['registrant']
#       assert_nil   items['validations']
#       assert_nil   items['external_order_number']
# 
#       # db records
#       assert_equal 1, CaApiRequest.count
#       assert_equal 1, Order.count
#       assert_equal 1, Validation.count
#       assert_equal 1, SiteSeal.count
#       assert_equal 1, CertificateOrder.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 1, SubOrderItem.count
#       assert_equal 1, LineItem.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 1, CertificateContent.last.domains.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#
#       # Funded Account is NOT charged
#       assert_equal 100000, FundedAccount.last.cents
#
#       # Order is paid
#       o = Order.first
#       assert_equal 0, o.cents
#       assert_equal @team.id, o.billable_id
#       assert_match 'paid', o.state
#       assert_match 'SslAccount', o.billable_type
#
#       # OrderTransaction - credit card was not charged
#       assert_equal 0, OrderTransaction.count
#     end
#   end
# end
