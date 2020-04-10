# require 'rails_helper'
#
# class CertCreateWithSavedContactsTest < ActionDispatch::IntegrationTest
#   describe 'create_v1_4' do
#     before do
#       api_main_setup
#       @team.funded_account.update(cents: 10000)
#       @amount_str = '$78.10'
#       @amount_int = 7810
#       @req = api_get_request_for_dv
#         .merge(api_get_server_software)
#         .merge(api_get_csr_registrant)
#         .merge(api_get_nonwildcard_csr_hash)
#         .merge(api_get_domain_for_csr)
#     end
#
#     # provide 1 saved contact for 'all' contacts:
#     # SHOULD  create a contact for each role "administrative", "billing", "technical"
#     #         and "validation" that duplicates attributes from saved contact.
#     it 'status 200: using all w/valid id' do
#       @team.saved_contacts.create(api_create_contact)
#       assert_equal 1, Contact.count
#
#       post api_certificate_create_v1_4_path(
#         @req.merge(
#           contacts: {
#             all: { saved_contact: Contact.first.id }
#           }
#         )
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
#       assert_equal 1, Registrant.count
#       assert_equal 1, Validation.count
#       assert_equal 1, SiteSeal.count
#       assert_equal 1, CertificateOrder.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 0, SignedCertificate.count
#       assert_equal 1, SubOrderItem.count
#       assert_equal 1, LineItem.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#
#       # saved contact
#       sc = CertificateContact.where(contactable_type: 'SslAccount').first
#       assert_equal 1, CertificateContact.where(contactable_type: 'SslAccount').count
#       # all 4 contacts (for certificate content) created from one saved contact
#       assert_equal 4, CertificateContact.where(contactable_type: 'CertificateContent').count
#       assert_equal [sc.first_name], CertificateContact.pluck(:first_name).uniq
#       assert_equal [sc.last_name], CertificateContact.pluck(:last_name).uniq
#       assert_equal [sc.company_name], CertificateContact.pluck(:company_name).uniq
#       assert_equal [sc.company_name], CertificateContact.pluck(:company_name).uniq
#       assert_equal [sc.address1], CertificateContact.pluck(:address1).uniq
#       assert_equal [sc.city], CertificateContact.pluck(:city).uniq
#       assert_equal [sc.state], CertificateContact.pluck(:state).uniq
#       assert_equal [sc.country], CertificateContact.pluck(:country).uniq
#       assert_equal [sc.postal_code], CertificateContact.pluck(:postal_code).uniq
#       assert_equal [sc.email], CertificateContact.pluck(:email).uniq
#       assert_equal [sc.phone], CertificateContact.pluck(:phone).uniq
#     end
#
#     # provide different saved contact for EACH contact role:
#     # SHOULD  create a contact for each role "administrative", "billing", "technical"
#     #         and "validation" that duplicates attributes from saved contact.
#     it 'status 200: by role w/valid saved contact' do
#       post api_certificate_create_v1_4_path(
#         @req.merge(
#           contacts: {
#             administrative: {
#               saved_contact: @team.saved_contacts.create(api_create_contact.merge(department: "administrative")).id
#             },
#             billing: {
#               saved_contact: @team.saved_contacts.create(api_create_contact.merge(department: "billing")).id
#             },
#             technical: {
#               saved_contact: @team.saved_contacts.create(api_create_contact.merge(department: "technical")).id
#             },
#             validation: {
#               saved_contact: @team.saved_contacts.create(api_create_contact.merge(department: "validation")).id
#             }
#           }
#         )
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
#       # 4 saved contacts
#       assert_equal 4, CertificateContact.where(contactable_type: 'SslAccount').count
#       # each of 4 contacts created from seperate saved contact
#       created = CertificateContact.where(contactable_type: 'CertificateContent')
#       assert_equal 4, created.count
#       assert_equal 1, created.where(department: 'administrative').count
#       assert_equal 1, created.where(department: 'billing').count
#       assert_equal 1, created.where(department: 'technical').count
#       assert_equal 1, created.where(department: 'validation').count
#       assert_equal [api_create_contact[:first_name]], CertificateContact.pluck(:first_name).uniq
#       assert_equal [api_create_contact[:last_name]], CertificateContact.pluck(:last_name).uniq
#       assert_equal [api_create_contact[:address1]], CertificateContact.pluck(:address1).uniq
#       assert_equal [api_create_contact[:city]], CertificateContact.pluck(:city).uniq
#       assert_equal [api_create_contact[:state]], CertificateContact.pluck(:state).uniq
#       assert_equal [api_create_contact[:country]], CertificateContact.pluck(:country).uniq
#       assert_equal [api_create_contact[:postal_code]], CertificateContact.pluck(:postal_code).uniq
#       assert_equal [api_create_contact[:email]], CertificateContact.pluck(:email).uniq
#       assert_equal [api_create_contact[:phone]], CertificateContact.pluck(:phone).uniq
#     end
#
#     # provide INVALID contact id for EACH contact role:
#     # SHOULD  return contact error for each role "administrative", "billing", "technical"
#     #         and "validation"
#     it 'status 200: by role w/INVALID saved contact' do
#       error = {
#         "contacts"=> [[
#           {"id"=>"Contact with id=5000 does not exist.", "role"=>"administrative"},
#           {"id"=>"Contact with id=5001 does not exist.", "role"=>"billing"},
#           {"id"=>"Contact with id=5002 does not exist.", "role"=>"technical"},
#           {"id"=>"Contact with id=5003 does not exist.", "role"=>"validation"}
#         ]]
#       }
#
#       post api_certificate_create_v1_4_path(
#         @req.merge(
#           contacts: {
#             administrative: { saved_contact: 5000 },
#             billing: { saved_contact: 5001 },
#             technical: { saved_contact: 5002 },
#             validation: { saved_contact: 5003 }
#           }
#         )
#       )
#       items = JSON.parse(body)
#
#       # response
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 1, items.count
#       assert_equal 4, items['errors']['contacts'].first.count
#       assert_equal error, items['errors']
#       assert_equal 1, InvalidApiCertificateRequest.count
#
#       # NO saved contacts
#       assert_equal 0, CertificateContact.where(contactable_type: 'SslAccount').count
#       # did not create any contacts for certificate order
#       assert_equal 0, CertificateContact.where(contactable_type: 'CertificateContent').count
#     end
#
#     # provide INVALID contact id for ALL contact roles:
#     # SHOULD  return contact error for "all"
#     it 'status 200: using all w/INVALID saved contact' do
#       error = {
#         "contacts"=> [[
#           {"id"=>"Contact with id=5000 does not exist.", "role"=>"all"},
#         ]]
#       }
#
#       post api_certificate_create_v1_4_path(
#         @req.merge(
#           contacts: {
#             all: { saved_contact: 5000 }
#           }
#         )
#       )
#       items = JSON.parse(body)
#
#       # response
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 1, items.count
#       assert_equal 1, items['errors']['contacts'].first.count
#       assert_equal error, items['errors']
#       assert_equal 1, InvalidApiCertificateRequest.count
#
#       # NO saved contacts
#       assert_equal 0, CertificateContact.where(contactable_type: 'SslAccount').count
#       # did not create any contacts for certificate order
#       assert_equal 0, CertificateContact.where(contactable_type: 'CertificateContent').count
#     end
#   end
# end
