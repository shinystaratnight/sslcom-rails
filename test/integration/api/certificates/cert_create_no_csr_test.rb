# require 'rails_helper'
#
# class CertCreateNoCsrTest < ActionDispatch::IntegrationTest
#   # POST /certificates (WITHOUT voucher/ref#)
#   describe 'create_v1_4' do
#     before do
#       api_main_setup
#       assert_equal 0, InvalidApiCertificateRequest.count
#       @req = api_get_request_for_dv
#     end
#
#     it 'status 200 error: not enough funds' do
#       post api_certificate_create_v1_4_path(@req)
#       items = JSON.parse(body)
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 1, items.count
#       refute_nil   items['errors']
#       refute_nil   items['errors']['funded_account']
#     end
#
#     it 'status 200: user error' do
#       post api_certificate_create_v1_4_path(account_key: @api_keys[:account_key])
#       items = JSON.parse(body)
#
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 1, items.count
#       assert_equal 4, items['errors'].count
#       refute_nil   items['errors']['login'] # didn't provide secret_key
#       refute_nil   items['errors']['secret_key']
#       refute_nil   items['errors']['period']
#       refute_nil   items['errors']['product']
#       assert_equal 1, InvalidApiCertificateRequest.count
#     end
#
#     it 'status 200: generate voucher' do
#       @team.funded_account.update(cents: 10000)
#       post api_certificate_create_v1_4_path(@req)
#       items = JSON.parse(body)
#
#       # db records
#       assert_equal (10000 - 7810), FundedAccount.last.cents
#       assert_equal 1, CaApiRequest.count
#       assert_equal 1, Order.count
#       assert_equal 1, Validation.count
#       assert_equal 1, SiteSeal.count
#       assert_equal 1, CertificateOrder.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 1, SubOrderItem.count
#       assert_equal 1, LineItem.count
#
#       # response
#       assert       match_response_schema('cert_create_voucher')
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 10, items.count
#       assert_match 'unused. waiting on certificate signing request (csr) from customer', items['order_status']
#       refute_nil   items['ref']
#       refute_nil   items['certificate_url']
#       refute_nil   items['receipt_url']
#       refute_nil   items['smart_seal_url']
#       refute_nil   items['validation_url']
#       assert_nil   items['external_order_number']
#     end
#   end
# end
