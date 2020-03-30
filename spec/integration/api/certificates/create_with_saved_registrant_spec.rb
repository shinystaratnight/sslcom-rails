# require 'rails_helper'
#
# class CreateWithSavedRegistrantTest < ActionDispatch::IntegrationTest
#   describe 'create_v1_4' do
#     before do
#       api_main_setup
#       @team.funded_account.update(cents: 10000)
#       @amount_str = '$78.10'
#       @amount_int = 7810
#       @req = api_get_request_for_dv
#         .merge(api_get_server_software)
#         .merge(api_get_csr_contacts)
#         .merge(api_get_nonwildcard_csr_hash)
#         .merge(api_get_domain_for_csr)
#     end
#
#     # provide VALID saved registrant:
#     # SHOULD create a registrant with attributes from saved registrant.
#     it 'status 200: valid saved registrant' do
#       @team.saved_registrants.create(api_get_registrant)
#       assert_equal 1, Contact.count
#       assert_equal 1, Registrant.count
#
#       post api_certificate_create_v1_4_path(
#         @req.merge(saved_registrant: Registrant.first.id)
#       )
#       items = JSON.parse(body)
#
#       # response
#       assert       match_response_schema('cert_create') # json schema
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 10, items.count
#       assert_equal @amount_str, items['order_amount']
#       assert_match 'validating, please wait', items['order_status']
#       assert_nil   items['validations']
#       refute_nil   items['ref']
#       refute_nil   items['registrant']
#       refute_nil   items['order_amount']
#       refute_nil   items['certificate_url']
#       refute_nil   items['receipt_url']
#       refute_nil   items['smart_seal_url']
#       refute_nil   items['validation_url']
#
#       # db records
#       assert_equal (10000 - @amount_int), FundedAccount.last.cents
#       assert_equal 2, CaApiRequest.count
#       assert_equal 0, CaDcvRequest.count
#       assert_equal 1, Order.count
#       assert_equal 2, Registrant.count
#       assert_equal 1, Validation.count
#       assert_equal 1, SiteSeal.count
#       assert_equal 1, CertificateOrder.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 0, SignedCertificate.count
#       assert_equal 1, SubOrderItem.count
#       assert_equal 1, LineItem.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#
#       # saved registrant
#       reg = Registrant.where(contactable_type: 'SslAccount').first
#       assert_equal 1, Registrant.where(contactable_type: 'SslAccount').count
#       # registrant created for CertificateContent
#       reg_copy = Registrant.where(contactable_type: 'CertificateContent').first
#       assert_equal 1, Registrant.where(contactable_type: 'CertificateContent').count
#       # registrant was created from saved registrant
#       # assert_equal reg.first_name, reg_copy.first_name
#       # assert_equal reg.last_name, reg_copy.last_name
#       assert_equal reg.company_name, reg_copy.company_name
#       assert_equal reg.address1, reg_copy.address1
#       assert_equal reg.city, reg_copy.city
#       assert_equal reg.state, reg_copy.state
#       assert_equal reg.country, reg_copy.country
#       assert_equal reg.postal_code, reg_copy.postal_code
#       # assert_equal reg.email, reg_copy.email
#       # assert_equal reg.phone, reg_copy.phone
#     end
#
#     # provide INVALID saved registrant id:
#     # SHOULD     return saved registrant error,
#     # SHOULD NOT create order, certificate order and charge
#     it 'status 200: INVALID saved registrant' do
#       error = {
#         "saved_registrant"=>[{"id"=>"Registrant with id=5000 does not exist."}]
#       }
#
#       post api_certificate_create_v1_4_path(
#         @req.merge(saved_registrant: 5000)
#       )
#       items = JSON.parse(body)
#
#       # response
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 1, items.count
#       assert_equal 1, items['errors']['saved_registrant'].first.count
#       assert_equal error, items['errors']
#       assert_equal 1, InvalidApiCertificateRequest.count
#
#       # db records
#       assert_equal 10000, FundedAccount.last.cents
#       assert_equal 1, CaApiRequest.count
#       assert_equal 0, CaDcvRequest.count
#       assert_equal 0, Order.count
#       assert_equal 0, Registrant.count
#       assert_equal 0, Validation.count
#       assert_equal 0, SiteSeal.count
#       assert_equal 0, CertificateOrder.count
#       assert_equal 0, CertificateContent.count
#       assert_equal 0, SignedCertificate.count
#       assert_equal 0, SubOrderItem.count
#       assert_equal 0, LineItem.count
#       assert_equal 1, InvalidApiCertificateRequest.count
#
#       # NO saved registrant
#       assert_equal 0, Registrant.where(contactable_type: 'SslAccount').count
#       # did not create registrant for certificate contact
#       assert_equal 0, Registrant.where(contactable_type: 'CertificateContent').count
#     end
#   end
# end
