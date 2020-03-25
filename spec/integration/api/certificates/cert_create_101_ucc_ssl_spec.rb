# require 'rails_helper'
#
# class CertCreate101UccSslTest < ActionDispatch::IntegrationTest
#   # POST /certificates
#   # UCC SSL (ucc256sslcom) | (a.k.a SANS) Certificate
#   #   A multi-domain ssl certificate that can secure up to 2000 domains.
#   #   Can add wildcard domains at premium price per each wildcard domain.
#   #   First 3 nonwildcard domains are one rate, domains 4-2000 are at a discounted rate per each domain.
#   describe 'create_v1_4' do
#     before do
#       api_main_setup
#       @team.funded_account.update(cents: 100000)
#       assert_equal 0, InvalidApiCertificateRequest.count
#       @req = api_get_request_for_ucc
#         .merge(api_get_server_software)
#         .merge(api_get_csr_registrant)
#         .merge(api_get_csr_contacts)
#     end
#
#     # Params:       domains hash
#     # NO params:    CSR hash
#     # Should:       save domains from array in CertificateContent, 20 total
#     #               charge for all 20 domains, 3 @ $39.05 and 17 @ $21.90
#     # Should NOT:   create certificate_names per each domain
#     #               create domain_control_validations per each domain
#     # ==========================================================================
#     it 'status 200: domains array, NO csr hash' do
#       post api_certificate_create_v1_4_path(
#         @req.merge(domains: (1..20).to_a.map {|n| "ssltestdomain#{n}.com"})
#       )
#       items = JSON.parse(body)
#
#       # response
#       assert       match_response_schema('cert_create_voucher')
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 10, items.count
#       assert_match 'unused. waiting on certificate signing request (csr) from customer', items['order_status']
#       assert_equal '$489.45', items['order_amount'] # 3 domains * $39.05 AND 17 domains * $21.90
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
#       assert_equal 20, CertificateContent.last.domains.count # 20 domains from domains hash are saved
#       assert_equal 0, CaDcvRequest.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#       assert_equal 0, Delayed::Job.count
#       assert_equal 0, Delayed::JobGroups::JobGroup.count
#
#       # 20 domains in domains hash
#       #   3  * 3905 = 11715 (serial: sslcomucc256ssl1yrdm, up to 3 domains)
#       #   17 * 2190 = 37230 (serial: sslcomucc256ssl1yradm, above 3 domains)
#       #             = 48945 (total)
#       assert_equal (100000 - 48945), FundedAccount.last.cents
#       assert_equal 3, api_get_sub_order_quantaty(@ucc_min_domains)
#       assert_equal 17, api_get_sub_order_quantaty(@ucc_max_domains)
#       assert_equal 0, api_get_sub_order_quantaty(@ucc_server_license)
#
#       # certificate names and csr NOT created
#       assert_equal 0, Csr.count
#       assert_equal 0, CertificateName.count
#       assert_equal 0, DomainControlValidation.count
#       assert_equal 'new', Validation.last.workflow_state
#     end
#
#     # Params: domians hash (2 total)
#     #         CSR hash (nonwildcard)
#     # Should: create a CSR
#     #         create CertificateName per each domain, 2 total
#     #         create DomainControlValidations per each domain, 2 total
#     # ==========================================================================
#     it 'status 200: domains hash, nonwildcard CSR hash' do
#       post api_certificate_create_v1_4_path(@req
#         .merge(api_get_domains_for_csr)
#         .merge(api_get_nonwildcard_csr_hash)
#       )
#       items = JSON.parse(body)
#       # response
#       assert       match_response_schema('cert_create') # json schema
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 10, items.count
#       assert_equal '$117.15', items['order_amount'] # 3 domains at $39.05
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
#       assert_equal 2, SubOrderItem.count
#       assert_equal 1, LineItem.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#       assert_equal 0, CaDcvRequest.count
#       assert_equal 0, Delayed::Job.count
#       assert_equal 0, Delayed::JobGroups::JobGroup.count
#
#       # at 3 domain limit
#       # should have 3 of product_variant_items (serial: 'sslcomucc256ssl1yrdm') at $39.05/each
#       assert_equal (100000 - 11715), FundedAccount.last.cents # 3 domains at $39.05 = $117.15
#       assert_equal 3, api_get_sub_order_quantaty(@ucc_min_domains)
#       assert_equal 0, api_get_sub_order_quantaty(@ucc_server_license)
#
#       # certificate names and csr created
#       api_assert_non_wildcard_csr
#       common_name = CertificateName.where(is_common_name: true)
#       assert_equal 2, CertificateName.count # 2 domains from domains hash
#       assert_equal 1, common_name.count     # only one common name for first domain in hash
#       assert_match api_get_domains_for_csr[:domains].keys.first.to_s, common_name.first.name
#       assert_equal api_get_domains_for_csr[:domains].keys.map(&:to_s).sort, CertificateName.pluck(:name).sort
#
#       # 2 dcvs created for 2 domains
#       dcv = DomainControlValidation
#       assert_equal 2, dcv.count                                     # only 2 domains via domains hash should be validated
#       assert_equal 0, dcv.where(csr_id: Csr.first.id).count         # extracted from csr
#       assert_equal 2, dcv.where.not(certificate_name_id: nil).count # 2 domains provided via domains params, not from csr
#       assert_equal 1, dcv.where(dcv_method: 'HTTP_CSR_HASH').count  # 1 domain, non-email
#       assert_equal 1, dcv.where(dcv_method: 'email', email_address: 'admin@ssltestdomain2.com').count # 1 domain is an email
#
#       api_ca_api_requests_when_csr
#     end
#
#     # Params:     domians hash (over 20 domains)
#     #             CSR hash (nonwildcard)
#     # Should:     create a delayed job group
#     #             create a delayed job for the all 22 domains
#     #             save domains from array in CertificateContent, 22 total
#     #             charge for all 22 domains, 3 @ $39.05 and 19 @ $21.90
#     #             create certificate_names per each domain, 22 total
#     #             create domain_control_validations per each domain
#     # ==========================================================================
#     it 'status 200: over 20 domains, nonwildcard CSR hash' do
#       domains = {
#         domains: (1..22).each.inject({}) do |d, n|
#           d["ssltest#{n}.com".to_sym] = {dcv: 'HTTP_CSR_HASH'}
#           d
#         end
#       }
#       post api_certificate_create_v1_4_path(@req.merge(domains)
#         .merge(api_get_nonwildcard_csr_hash)
#       )
#       items = JSON.parse(body)
#
#       # response
#       assert       match_response_schema('cert_create_voucher')
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 10, items.count
#       assert_includes items['order_status'], 'validat'
#       assert_equal '$533.25', items['order_amount'] # 3 domains * $39.05 AND 19 domains * $21.90
#       refute_nil   items['ref']
#       refute_nil   items['certificate_url']
#       refute_nil   items['receipt_url']
#       refute_nil   items['smart_seal_url']
#       refute_nil   items['validation_url']
#       refute_nil   items['registrant']
#       assert_nil   items['validations']
#       assert_nil   items['external_order_number']
#
#       # db records
#       # assert_equal 2, CaApiRequest.count # request to Comodo API and ssl.com
#       assert_equal 1, Order.count
#       assert_equal 1, Validation.count
#       assert_equal 1, SiteSeal.count
#       assert_equal 1, CertificateOrder.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 3, SubOrderItem.count
#       assert_equal 1, LineItem.count
#       assert_equal 1, CertificateContent.count
#       # 22 domains from domains hash are saved
#       assert_equal 22, CertificateContent.last.domains.count
#       assert_equal 0, CaDcvRequest.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#
#       # charged for 22 domains in domains hash
#       #   3  * 3905 = 11715 (serial: sslcomucc256ssl1yrdm, up to 3 domains)
#       #   19 * 2190 = 37230 (serial: sslcomucc256ssl1yradm, above 3 domains)
#       #             = 53325 (total)
#       assert_equal (100000 - 53325), FundedAccount.last.cents
#       assert_equal 3,  api_get_sub_order_quantaty(@ucc_min_domains)
#       assert_equal 19, api_get_sub_order_quantaty(@ucc_max_domains)
#       assert_equal 0,  api_get_sub_order_quantaty(@ucc_server_license)
#
#       # certificate names and csr created
#       api_assert_non_wildcard_csr
#
#       cert_name    = CertificateName.pluck(:name)
#       common_name  = CertificateName.where(is_common_name: true)
#       # assert_equal 22, CertificateName.count # TODO: throws error if delayed job is in progress
#       # assert_equal 1, common_name.count
#       # assert_match domains[:domains].keys.first.to_s, common_name.first.name
#       domains[:domains].keys.map(&:to_s).each {|name| assert cert_name.include?(name)}
#
#       # dcv is created for each domain
#       assert_equal 22, DomainControlValidation.count
#       assert_equal 'new', Validation.last.workflow_state
#
#       # delayed job not created
#       assert_equal    0, Delayed::Job.count
#       assert_equal    0, Delayed::JobGroups::JobGroup.count
#     end
#
#     # Params:    wildcard CSR hash
#     # NO params: domians hash
#     # Should:    allow wildcard domain
#     #            charge different price for wildcard domain
#     #            extract domain from CSR hash
#     # ==========================================================================
#     it 'status 200: NO domains hash, wildcard CSR hash' do
#       post api_certificate_create_v1_4_path(@req.merge(api_get_wildcard_csr_hash))
#       items = JSON.parse(body)
#
#       # response
#       assert       match_response_schema('cert_create_voucher')
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 10, items.count
#       assert_includes items['order_status'], 'validat'
#       # 3 domains * $39.05 (fixed default) AND 1 wildcard domain * $51.10
#       assert_equal '$168.25', items['order_amount']
#       refute_nil   items['ref']
#       refute_nil   items['certificate_url']
#       refute_nil   items['receipt_url']
#       refute_nil   items['smart_seal_url']
#       refute_nil   items['validation_url']
#       refute_nil   items['registrant']
#       assert_nil   items['validations']
#       assert_nil   items['external_order_number']
#
#       # db records
#       assert_equal 2, CaApiRequest.count
#       assert_equal 1, Order.count
#       assert_equal 1, Validation.count
#       assert_equal 1, SiteSeal.count
#       assert_equal 1, CertificateOrder.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 3, SubOrderItem.count
#       assert_equal 1, LineItem.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 1, CertificateContent.last.domains.count # 1 domain from CSR hash
#       assert_equal 0, CaDcvRequest.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#       assert_equal 0, Delayed::Job.count
#       assert_equal 0, Delayed::JobGroups::JobGroup.count
#
#       # 1 domain from wildcard CSR hash
#       #   3  * 3905 = 11715 (serial: sslcomucc256ssl1yrdm, up to 3 domains), added by default for ucc pricing
#       #   1 * 5110  = 5110 (serial: sslcomucc256ssl1yrwcdm)
#       #             = 16825 (total)
#       assert_equal (100000 - 16825), FundedAccount.last.cents
#       assert_equal 3,  api_get_sub_order_quantaty(@ucc_min_domains) # default
#       assert_equal 0,  api_get_sub_order_quantaty(@ucc_server_license)
#       assert_equal 1,  api_get_sub_order_quantaty(@ucc_wildcard)
#
#       # certificate name and CSR created
#       api_assert_wildcard_csr
#       assert_equal 1, CertificateName.count
#       assert_equal 1, CertificateName.where(is_common_name: true).count
#       assert_match '*.rubricae.es', CertificateName.first.name
#
#       # 1 dcv created for domain in CSR hash
#       assert_equal 1, DomainControlValidation.count
#       assert_equal 'new', Validation.last.workflow_state
#
#       # CaApiRequest, 2 total
#       api_ca_api_requests_when_csr
#     end
#
#     # Params:     domains hash (over 500 domains)
#     # No Params:  CSR hash
#     # Should:     return status code 200
#     #             response should have domains error
#     # ==========================================================================
#     # it 'status 200: over 500 domain max limit, NO CSR hash' do
#       # @team.funded_account.update(cents: 9000000)
#       # post api_certificate_create_v1_4_path(
#       #   @req.merge(domains: (1..501).to_a.map {|n| "ssltestdomain#{n}.com"})
#       # )
#       # items = JSON.parse(body)
#       #
#       # # response
#       # assert       response.success?
#       # assert_equal 200, status
#       # assert_equal 1, items.count
#       # refute_nil   items['errors']
#       # assert_match 'You have exceeded the maximum of 500 domain(s) or subdomains for this certificate.', items['errors']['domains'].first
#       #
#       # # db records
#       # assert_equal 1, CaApiRequest.count
#       # assert_equal 0, CaDcvRequest.count
#       # assert_equal 0, Order.count
#       # assert_equal 0, Registrant.count
#       # assert_equal 0, Validation.count
#       # assert_equal 0, SiteSeal.count
#       # assert_equal 0, CertificateOrder.count
#       # assert_equal 0, CertificateContact.count
#       # assert_equal 0, CertificateContent.count
#       # assert_equal 0, SignedCertificate.count
#       # assert_equal 0, SubOrderItem.count
#       # assert_equal 0, LineItem.count
#       # assert_equal 1, InvalidApiCertificateRequest.count
#       # assert_match 'ssl.com', InvalidApiCertificateRequest.first.ca
#       # assert_equal 0, Delayed::Job.count
#       # assert_equal 0, Delayed::JobGroups::JobGroup.count
#     # end
#   end
# end
