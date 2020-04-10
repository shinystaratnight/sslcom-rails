# require 'rails_helper'
#
# class CertCreateWithCsrTest < ActionDispatch::IntegrationTest
#   describe 'create_v1_4' do
#     before do
#       api_main_setup
#       @team.funded_account.update(cents: 10000)
#       assert_equal 0, InvalidApiCertificateRequest.count
#       @amount_str = '$78.10'
#       @amount_int = 7810
#     end
#
#     # includes params:
#     #   4 valid contacts
#     #   1 domain in addition to csr domain
#     #   valid registrant
#     #   non-wildcard csr
#     it 'status 200: single domain dv' do
#       req = api_get_request_for_dv
#         .merge(api_get_server_software)
#         .merge(api_get_csr_registrant)
#         .merge(api_get_csr_contacts)
#         .merge(api_get_nonwildcard_csr_hash)
#         .merge(api_get_domain_for_csr)
#
#       post api_certificate_create_v1_4_path(req)
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
#       ca_request_1 = CaApiRequest.find_by_api_requestable_type 'SslAccount'
#       ca_request_2 = CaApiRequest.find_by_api_requestable_type 'Csr'
#       csr          = Csr.first
#       dcv          = DomainControlValidation
#       assert_equal (10000 - @amount_int), FundedAccount.last.cents
#       assert_equal 2, CaApiRequest.count
#       assert_equal 0, CaDcvRequest.count
#       assert_equal 1, Order.count
#       assert_equal 1, Registrant.count
#       assert_equal 1, Validation.count
#       assert_equal 1, SiteSeal.count
#       assert_equal 1, CertificateOrder.count
#       assert_equal 4, CertificateContact.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 0, SignedCertificate.count
#       assert_equal 1, SubOrderItem.count
#       assert_equal 1, LineItem.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#
#       assert_equal 1, Csr.count
#       assert_match 'qlikdev.ezops.com', csr.common_name
#       assert_match 'EZOPS Inc', csr.organization
#       assert_match 'IT', csr.organization_unit
#       assert_match 'vishal@ezops.com', csr.email
#       assert_match 'sha256WithRSAEncryption', csr.sig_alg
#       refute_nil   csr.body
#
#       assert_equal 2, dcv.count
#       assert_equal 1, dcv.where(csr_id: csr.id).count # extracted from csr
#       assert_equal 1, dcv.where.not(certificate_name_id: nil).count # 2 domains provided via domains params, not from csr
#       assert_equal 2, dcv.where(dcv_method: 'HTTP_CSR_HASH').count  # 2 domain names, one provided and one from csr
#       assert_equal 0, dcv.where(dcv_method: 'email', email_address: 'admin@ssltestdomain2.com').count # 1 domain is an email
#
#       assert_equal 2, CertificateName.count # 2 domains provided, 1 from csr
#       assert_equal %w{mail.ssltestdomain1.com qlikdev.ezops.com}.sort, CertificateName.pluck(:name).sort
#       assert_match 'ssl.com', ca_request_1.ca
#       assert_match 'ApiCertificateCreate_v1_4', ca_request_1.type
#       assert_match 'comodo', ca_request_2.ca
#       assert_match 'CaCertificateRequest', ca_request_2.type
#       assert_match 'https://secure.trust-provider.com/products/!AutoApplySSL', ca_request_2.request_url
#     end
#
#     # includes params:
#     #   4 valid contacts
#     #   1 domain in addition to csr domain
#     #   valid registrant
#     #   non-wildcard csr
#     it 'status 200' do
#       req = api_get_request_for_dv
#         .merge(api_get_server_software)
#         .merge(api_get_csr_registrant)
#         .merge(api_get_csr_contacts)
#         .merge(api_get_nonwildcard_csr_hash)
#         .merge(api_get_domain_for_csr)
#
#       post api_certificate_create_v1_4_path(req)
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
#       assert_nil   items['external_order_number']
#
#       # db records
#       ca_request_1 = CaApiRequest.find_by_api_requestable_type 'SslAccount'
#       ca_request_2 = CaApiRequest.find_by_api_requestable_type 'Csr'
#       csr          = Csr.first
#       dcv          = DomainControlValidation
#       assert_equal (10000 - @amount_int), FundedAccount.last.cents
#       assert_equal 2, CaApiRequest.count
#       assert_equal 0, CaDcvRequest.count
#       assert_equal 1, Order.count
#       assert_equal 1, Registrant.count
#       assert_equal 1, Validation.count
#       assert_equal 1, SiteSeal.count
#       assert_equal 1, CertificateOrder.count
#       assert_equal 4, CertificateContact.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 0, SignedCertificate.count
#       assert_equal 1, SubOrderItem.count
#       assert_equal 1, LineItem.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#
#       assert_equal 1, Csr.count
#       assert_match 'qlikdev.ezops.com', csr.common_name
#       assert_match 'EZOPS Inc', csr.organization
#       assert_match 'IT', csr.organization_unit
#       assert_match 'vishal@ezops.com', csr.email
#       assert_match 'sha256WithRSAEncryption', csr.sig_alg
#       refute_nil   csr.body
#
#       assert_equal 2, dcv.count
#       assert_equal 1, dcv.where(csr_id: csr.id).count # extracted from csr
#       assert_equal 1, dcv.where.not(certificate_name_id: nil).count # 1 domain provided via domains params, not from csr
#       assert_equal 2, dcv.where(dcv_method: 'HTTP_CSR_HASH').count  # 2 domain names, one provided and one from csr
#
#       assert_equal 2, CertificateName.count # 1 domains provided, ignore one from csr
#       assert_equal ['qlikdev.ezops.com', 'mail.ssltestdomain1.com'], CertificateName.pluck(:name)
#       assert_match 'ssl.com', ca_request_1.ca
#       assert_match 'ApiCertificateCreate_v1_4', ca_request_1.type
#       assert_match 'comodo', ca_request_2.ca
#       assert_match 'CaCertificateRequest', ca_request_2.type
#       assert_match 'https://secure.trust-provider.com/products/!AutoApplySSL', ca_request_2.request_url
#     end
#
#   end
# end
