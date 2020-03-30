# require 'rails_helper'
#
# class CertCreate106BasicSslTest < ActionDispatch::IntegrationTest
#   # POST /certificates
#   # Basic SSL (basic256sslcom) Certificate
#   #   Only 1 non-wildcard domain.
#   describe 'create_v1_4' do
#     before do
#       api_main_setup
#       @team.funded_account.update(cents: 100000)
#       assert_equal 0, InvalidApiCertificateRequest.count
#       @req = api_get_request_for_dv
#         .merge(api_get_server_software)
#         .merge(api_get_csr_registrant)
#         .merge(api_get_csr_contacts)
#       @amount_int = 7810
#       @amount_str = '$78.10'
#     end
#
#     # Params:       domains hash (w/1 nonwildcard domain)
#     # NO params:    CSR hash
#     # Should:       save domains from array in CertificateContent, 1 total
#     #               charge for 1 domain @ $78.10
#     # Should NOT:   create 1 certificate name
#     #               create csr
#     # ==========================================================================
#     it 'status 200: domains array, NO csr hash' do
#       post api_certificate_create_v1_4_path(
#         @req.merge(domains: ['basicssldomain.com'])
#       )
#       items = JSON.parse(body)
#
#       # response
#       assert       match_response_schema('cert_create_voucher') # json schema
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 10, items.count
#       assert_match 'unused. waiting on certificate signing request (csr) from customer', items['order_status']
#       assert_equal @amount_str, items['order_amount']
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
#       assert_equal 1, CertificateContent.last.domains.count # 1 domain from domains hash is saved
#       assert_equal 0, CertificateName.count
#       assert_equal 0, CaDcvRequest.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#       assert_equal 0, Delayed::Job.count
#       assert_equal 0, Delayed::JobGroups::JobGroup.count
#       assert_equal 'new', Validation.last.workflow_state
#       assert_equal 'new', SiteSeal.last.workflow_state
#
#       # Deduct for 1 domain @ $78.10 (serial: sslcombasic256ssl1yr)
#       assert_equal (100000 - @amount_int), FundedAccount.last.cents
#       assert_equal 1, api_get_sub_order_quantaty(@basic_domains)
#
#       # csr and dcv NOT created
#       assert_equal 0, Csr.count
#       assert_equal 0, DomainControlValidation.count
#     end
#
#     # Params:       domains hash (w/1 nonwildcard domain)
#     # NO params:    nonwildcard CSR hash
#     # Should:       save domains from array in CertificateContent, 1 total
#     #               charge for 1 domain @ $78.10
#     #               create 1 certificate name
#     #               create 1 dcv
#     #               create 1 csv
#     # ==========================================================================
#     it 'status 200: domains hash, nonwildcard CSR hash' do
#       post api_certificate_create_v1_4_path(@req
#         .merge(domains: {'basicssldomain.com': {dcv: 'HTTP_CSR_HASH'}})
#         .merge(api_get_nonwildcard_csr_hash)
#       )
#       items = JSON.parse(body)
#
#       # response
#       assert       match_response_schema('cert_create') # json schema
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 10, items.count
#       assert_equal @amount_str, items['order_amount'] # 1 domain at $78.10
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
#       assert_equal 0, CaDcvRequest.count
#       assert_equal 0, Delayed::Job.count
#       assert_equal 0, Delayed::JobGroups::JobGroup.count
#
#       # Deduct for 1 domain @ $78.10 (serial: sslcombasic256ssl1yr)
#       assert_equal (100000 - @amount_int), FundedAccount.last.cents
#       assert_equal 1, api_get_sub_order_quantaty(@basic_domains)
#
#       # certificate name and csr created
#       api_assert_non_wildcard_csr
#
#       common_name = CertificateName.where(is_common_name: true)
#       assert_equal 1, CertificateName.count # 1 domain from domains hash
#       assert_equal 1, common_name.count     # 1 common name
#       assert_match 'basicssldomain.com', common_name.first.name
#
#       # 2 dcvs created for 2 domains
#       dcv = DomainControlValidation
#       assert_equal 2, dcv.count                                     # only 1 domain via domains hash should be validated
#       assert_equal 1, dcv.where(csr_id: Csr.first.id).count         # common name TODO
#       assert_equal 1, dcv.where.not(certificate_name_id: nil).count # 1 domain provided via domains params, not from csr
#       assert_equal 2, dcv.where(dcv_method: 'HTTP_CSR_HASH').count  # 1 domain, non-email
#
#       api_ca_api_requests_when_csr
#     end
#
#     # Params:    nonwildcard CSR hash
#     # NO params: domians hash
#     # Should:    save domains from array in CertificateContent, 1 total
#     #            charge for 1 domain @ $78.10
#     #            create 1 certificate name
#     #            create 1 dcv
#     #            create 1 csv
#     #            extract domain from CSR hash
#     # ==========================================================================
#     it 'status 200: nonwildcard CSR hash, NO domains hash' do
#       post api_certificate_create_v1_4_path(
#         @req.merge(api_get_nonwildcard_csr_hash)
#       )
#       items = JSON.parse(body)
#
#       # response
#       assert       match_response_schema('cert_create') # json schema
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 10, items.count
#       assert_equal @amount_str, items['order_amount'] # 1 domain at $78.10
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
#       assert_equal 0, CaDcvRequest.count
#       assert_equal 0, Delayed::Job.count
#       assert_equal 0, Delayed::JobGroups::JobGroup.count
#
#       # Deduct for 1 domain @ $78.10 (serial: sslcombasic256ssl1yr)
#       assert_equal (100000 - @amount_int), FundedAccount.last.cents
#       assert_equal 1, api_get_sub_order_quantaty(@basic_domains)
#
#       # certificate name (as CN) and csr created
#       api_assert_non_wildcard_csr
#       assert_equal 1, CertificateName.count
#       assert_equal 1, CertificateName.where(is_common_name: true).count
#       assert_match 'qlikdev.ezops.com', CertificateName.first.name
#
#       # 1 dcv created for domain in CSR hash
#       assert_equal 2, DomainControlValidation.count
#       assert_equal 'new', Validation.last.workflow_state
#
#       # CaApiRequest, 2 total
#       api_ca_api_requests_when_csr
#     end
#
#     # Params:     wildcard CSR hash
#     # No Params:  domains hash
#     # Should:     return status code 200
#     #             response should have domains error
#     # ==========================================================================
#     it 'status 200 error: wildcard CSR hash, NO domains hash' do
#       @team.funded_account.update(cents: 9000000)
#       post api_certificate_create_v1_4_path(
#         @req.merge(api_get_wildcard_csr_hash)
#       )
#       items = JSON.parse(body)
#
#       # response
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 1, items.count
#       refute_nil   items['errors']
#       assert_match 'cannot begin with *. since the order does not allow wildcards', items['errors']['signing_request'].first
#
#       # db records
#       assert_equal 1, CaApiRequest.count
#       assert_equal 0, CaDcvRequest.count
#       assert_equal 0, Order.count
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
#       assert_equal 0, Delayed::Job.count
#       assert_equal 0, Delayed::JobGroups::JobGroup.count
#     end
#
#     # Params:     domains hash (over the limit of 1 domain)
#     # No Params:  domains hash
#     # Should:     return status code 200
#     #             response should have domains error
#     # ==========================================================================
#     # TODO: After domain validation is enabled again, uncomment
#     # it 'status 200 error: domains hash (over max limit), NO CSR hash' do
#     #   @team.funded_account.update(cents: 9000000)
#     #   post api_certificate_create_v1_4_path(
#     #     @req.merge(domains: %w{basicssldomain1.com basicssldomain1.com})
#     #   )
#     #   items = JSON.parse(body)
#     #
#     #   # response
#     #   assert       response.success?
#     #   assert_equal 200, status
#     #   assert_equal 1, items.count
#     #   refute_nil   items['errors']
#     #   assert_match 'You have exceeded the maximum of 1 domain(s) or subdomains for this certificate.', items['errors']['domains'].first
#     #
#     #   # db records
#     #   assert_equal 1, CaApiRequest.count
#     #   assert_equal 0, CaDcvRequest.count
#     #   assert_equal 0, Order.count
#     #   assert_equal 0, Registrant.count
#     #   assert_equal 0, Validation.count
#     #   assert_equal 0, SiteSeal.count
#     #   assert_equal 0, CertificateOrder.count
#     #   assert_equal 0, CertificateContact.count
#     #   assert_equal 0, CertificateContent.count
#     #   assert_equal 0, SignedCertificate.count
#     #   assert_equal 0, SubOrderItem.count
#     #   assert_equal 0, LineItem.count
#     #   assert_equal 1, InvalidApiCertificateRequest.count
#     #   assert_equal 0, Delayed::Job.count
#     #   assert_equal 0, Delayed::JobGroups::JobGroup.count
#     # end
#   end
# end
