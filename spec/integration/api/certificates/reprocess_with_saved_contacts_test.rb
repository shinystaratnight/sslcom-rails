# require 'rails_helper'
#
# class ReprocessWithSavedContactsTest < ActionDispatch::IntegrationTest
#   describe 'update_v1_4' do
#     before do
#       api_main_setup
#       @team.funded_account.update(cents: 10000)
#       # create and issue valid certificate order for reprocess
#       post api_certificate_create_v1_4_path(
#         api_get_request_for_dv
#           .merge(api_get_server_software)
#           .merge(api_get_csr_registrant)
#           .merge(api_get_csr_contacts)
#           .merge(api_get_nonwildcard_csr_hash)
#           .merge(api_get_domain_for_csr)
#       )
#       issue_certificate(Csr.last.id) # only issued certificate can be rekeyed.
#
#       assert_equal 1, CertificateOrder.count
#       assert_equal 4, CertificateContact.count
#       assert_equal 1, SignedCertificate.count
#       assert_match 'issued', SignedCertificate.last.status
#
#       @first_name = 'Reprocess Test'
#       @amount_str = '$78.10'
#       @amount_int = 7810
#       @ref        = CertificateOrder.last.ref
#       @rekey_req  = @api_keys
#         .merge(api_get_csr_registrant)
#         .merge(api_get_nonwildcard_csr_hash)
#         .merge(api_get_domain_for_csr)
#         .merge(api_get_server_software)
#     end
#
#     # provide a list of saved contacts.
#     # SHOULD  Create 4 certificate contacts for each role "administrative", "billing", "technical"
#     #         and "validation" that duplicates attributes from 4 saved contacts
#     #         with parent_id populated.
#     if Contact.optional_contacts?
#       it 'status 200: saved_contacts param' do
#         ac = @team.saved_contacts.create(api_create_contact
#           .merge(first_name: 'Administrative', roles: ['administrative']))
#         vc = @team.saved_contacts.create(api_create_contact
#           .merge(first_name: 'Validation', roles: ['validation']))
#         tc = @team.saved_contacts.create(api_create_contact
#           .merge(first_name: 'Technical', roles: ['technical']))
#         bc = @team.saved_contacts.create(api_create_contact
#           .merge(first_name: 'Billing', roles: ['billing']))
#         invalid = @team.saved_contacts.new(api_create_contact
#           .merge(first_name: nil, last_name: 'admin', roles: ['administrative']))
#         invalid.save(validate: false)
#
#         assert_equal 5, @team.saved_contacts.count
#         assert_equal 10, Contact.count
#         assert_equal 9, CertificateContact.count
#         assert_equal 1, Registrant.count
#
#         put api_certificate_update_v1_4_path(@ref, @rekey_req # reprocess
#           .merge(
#             contacts: { saved_contacts: @team.saved_contacts.map(&:id)[0..3] }
#           )
#         )
#         items = JSON.parse(body)
#
#         # response
#         assert       match_response_schema('cert_create') # json schema
#         assert       response.success?
#         assert_equal 200, status
#         assert_equal 10, items.count
#         assert_equal @amount_str, items['order_amount']
#         assert_match 'validating, please wait', items['order_status']
#         assert_nil   items['validations']
#         refute_nil   items['ref']
#         refute_nil   items['registrant']
#         refute_nil   items['order_amount']
#         refute_nil   items['certificate_url']
#         refute_nil   items['receipt_url']
#         refute_nil   items['smart_seal_url']
#         refute_nil   items['validation_url']
#
#         # contacts
#         assert_equal 15, Contact.count
#         # 1 saved contact, 2 registrants, 4 for certificate create, 4 additional for reprocess
#         assert_equal 2, Registrant.count
#         assert_equal 5, CertificateContact.where(contactable_type: 'SslAccount').count
#         assert_equal 8, CertificateContact.where(contactable_type: 'CertificateContent').count
#         assert_equal 4, CertificateContact.where(contactable_type: 'CertificateContent').where.not(parent_id: nil).count
#         assert_equal 5, @team.saved_contacts.count
#         # each of 4 saved contacts has been duplicated for certificate content contacts
#         [ac, vc, tc, bc].each do |sc|
#           assert_equal 1, CertificateContact.where(
#             contactable_type: 'CertificateContent',
#             parent_id:        sc.id,
#             first_name:       sc.first_name
#           ).count
#         end
#
#         # Invalid saved contact ids (do not exist):
#         #   e.g.: contacts {saved_contacts: [invalid_id_1, invalid_id_2]}
#         # SHOULD  return error, create zero certificate contacts
#         # ========================================================================
#         error = {
#           "contacts"=> [[
#             {"saved_contacts"=>"Contacts with ids 1000, 2000, 3000 do not exist."}
#           ]]
#         }
#         issue_certificate(Csr.last.id)
#         put api_certificate_update_v1_4_path(@ref, @rekey_req # reprocess
#           .merge(contacts: { saved_contacts: [1000, 2000, 3000] })
#         )
#         # response
#         items = JSON.parse(body)
#         assert       response.success?
#         assert_equal 200, status
#         assert_equal 1, items.count
#         assert_equal 1, items['errors']['contacts'].first.count
#         assert_equal error, items['errors']
#         assert_equal 1, InvalidApiCertificateRequest.count
#
#         # contacts
#         assert_equal 15, Contact.count
#         # New contacts have not been created
#         assert_equal 2, Registrant.count
#         assert_equal 5, CertificateContact.where(contactable_type: 'SslAccount').count
#         assert_equal 8, CertificateContact.where(contactable_type: 'CertificateContent').count
#         assert_equal 4, CertificateContact.where(contactable_type: 'CertificateContent').where.not(parent_id: nil).count
#         assert_equal 5, @team.saved_contacts.count
#
#         # Invalid saved contact: (saved contact passed is invalid)
#         #   e.g.: contacts {saved_contacts: [contact_id]}
#         # SHOULD  return error, create zero certificate contacts
#         # ========================================================================
#         error = {
#           "contacts"=> [
#             {"saved_contact_#{invalid.id}" => "Failed to create contact: First name can't be blank."}
#           ]
#         }
#         refute invalid.valid?
#
#         issue_certificate(Csr.last.id)
#         put api_certificate_update_v1_4_path(@ref, @rekey_req # reprocess
#           .merge(contacts: {saved_contacts: [invalid.id]})
#         )
#         # response
#         items = JSON.parse(body)
#         assert       response.success?
#         assert_equal 200, status
#         assert_equal 1, items.count
#         assert_equal 1, items['errors']['contacts'].first.count
#         assert_equal error, items['errors']
#         assert_equal 1, InvalidApiCertificateRequest.count
#
#       end
#     end
#     # provide 1 saved contact for 'all' contacts on reprocess/rekey.
#     # SHOULD  create a contact for each role "administrative", "billing", "technical"
#     #         and "validation" that duplicates attributes from saved contact
#     #         with first_name 'Reprocess Test'.
#     it 'status 200: using all w/valid id' do
#       @team.saved_contacts.create(api_create_contact.merge(first_name: @first_name))
#       assert_equal 1, @team.saved_contacts.count
#       assert_equal 6, Contact.count
#       assert_equal 5, CertificateContact.count
#       assert_equal 1, Registrant.count
#
#       put api_certificate_update_v1_4_path(@ref, @rekey_req # reprocess
#         .merge(
#           contacts: {
#             all: { saved_contact: @team.saved_contacts.first.id }
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
#       assert_equal 4, CaApiRequest.count
#       assert_equal 0, CaDcvRequest.count
#       assert_equal 1, Order.pluck(:id).uniq.count
#       assert_equal 1, Validation.count
#       assert_equal 1, SiteSeal.count
#       assert_equal 1, CertificateOrder.pluck(:id).uniq.count
#       assert_equal 2, CertificateContent.count
#       assert_equal 1, SignedCertificate.count
#       assert_equal 1, SubOrderItem.count
#       assert_equal 1, LineItem.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#
#       # contacts
#       assert_equal 11, Contact.count
#       # 1 saved contact, 2 registrants, 4 for certificate create, 4 additional for reprocess
#       assert_equal 2, Registrant.count
#       assert_equal 1, CertificateContact.where(contactable_type: 'SslAccount').count
#       assert_equal 8, CertificateContact.where(contactable_type: 'CertificateContent').count
#       assert_equal 4, CertificateContact.where(contactable_type: 'CertificateContent', first_name: @first_name).count
#       assert_equal 1, @team.saved_contacts.count
#       sc           = @team.saved_contacts.first
#       cc_on_create = CertificateOrder.first.certificate_contents.first.certificate_contacts
#       cc_on_rekey  = CertificateOrder.first.certificate_contents.last.certificate_contacts
#
#       # all 4 contacts (for certificate content) created from one saved contact
#       assert_equal [api_create_contact[:first_name]], cc_on_create.pluck(:first_name).uniq
#       assert_equal [@first_name], cc_on_rekey.pluck(:first_name).uniq
#       assert_equal [sc.first_name], cc_on_rekey.pluck(:first_name).uniq
#       assert_equal [sc.last_name], cc_on_rekey.pluck(:last_name).uniq
#       assert_equal [sc.company_name], cc_on_rekey.pluck(:company_name).uniq
#       assert_equal [sc.company_name], cc_on_rekey.pluck(:company_name).uniq
#       assert_equal [sc.address1], cc_on_rekey.pluck(:address1).uniq
#       assert_equal [sc.city], cc_on_rekey.pluck(:city).uniq
#       assert_equal [sc.state], cc_on_rekey.pluck(:state).uniq
#       assert_equal [sc.country], cc_on_rekey.pluck(:country).uniq
#       assert_equal [sc.postal_code], cc_on_rekey.pluck(:postal_code).uniq
#       assert_equal [sc.email], cc_on_rekey.pluck(:email).uniq
#       assert_equal [sc.phone], cc_on_rekey.pluck(:phone).uniq
#     end
#
#     # provide different saved contact for EACH contact role:
#     # SHOULD  create a contact for each role "administrative", "billing", "technical"
#     #         and "validation" that duplicates attributes from the 4 saved contacts.
#     it 'status 200: by role w/valid saved contact' do
#       put api_certificate_update_v1_4_path(@ref, @rekey_req # reprocess
#         .merge(
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
#       cc_on_rekey  = CertificateOrder.first.certificate_contents.last.certificate_contacts
#       assert_equal 8, created.count
#       assert_equal 1, created.where(department: 'administrative').count
#       assert_equal 1, created.where(department: 'billing').count
#       assert_equal 1, created.where(department: 'technical').count
#       assert_equal 1, created.where(department: 'validation').count
#       assert_equal [api_create_contact[:first_name]], cc_on_rekey.pluck(:first_name).uniq
#       assert_equal [api_create_contact[:last_name]], cc_on_rekey.pluck(:last_name).uniq
#       assert_equal [api_create_contact[:address1]], cc_on_rekey.pluck(:address1).uniq
#       assert_equal [api_create_contact[:city]], cc_on_rekey.pluck(:city).uniq
#       assert_equal [api_create_contact[:state]], cc_on_rekey.pluck(:state).uniq
#       assert_equal [api_create_contact[:country]], cc_on_rekey.pluck(:country).uniq
#       assert_equal [api_create_contact[:postal_code]], cc_on_rekey.pluck(:postal_code).uniq
#       assert_equal [api_create_contact[:email]], cc_on_rekey.pluck(:email).uniq
#       assert_equal [api_create_contact[:phone]], cc_on_rekey.pluck(:phone).uniq
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
#       put api_certificate_update_v1_4_path(@ref, @rekey_req # reprocess
#         .merge(
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
#       # did not create any contacts for reprocess, only 4 contacts from create remain
#       assert_equal 4, CertificateContact.where(contactable_type: 'CertificateContent').count
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
#       put api_certificate_update_v1_4_path(@ref, @rekey_req # reprocess
#         .merge(
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
#       # did not create any contacts for reprocess, only 4 contacts from create remain
#       assert_equal 4, CertificateContact.where(contactable_type: 'CertificateContent').count
#     end
#   end
# end
