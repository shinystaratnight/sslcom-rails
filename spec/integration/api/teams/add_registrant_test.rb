# require 'rails_helper'
#
# class AddRegistrantTest < ActionDispatch::IntegrationTest
#   describe 'add_registrant' do
#     before do
#       api_min_setup
#       assert_equal 0, InvalidApiCertificateRequest.count
#     end
#
#     it 'status 200: valid registrant' do
#       req = @api_keys.merge(api_get_registrant)
#
#       post api_team_add_registrant_path(req)
#       items = JSON.parse(body)
#
#       # response
#       assert       match_response_schema('team_valid_registrant') # json schema
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 18, items.count
#       assert_nil   items['title']
#       refute_nil   items['company_name']
#       refute_nil   items['first_name']
#       refute_nil   items['last_name']
#       assert_nil   items['po_box']
#       refute_nil   items['address1']
#       refute_nil   items['city']
#       refute_nil   items['state']
#       refute_nil   items['country']
#       refute_nil   items['postal_code']
#       refute_nil   items['email']
#       refute_nil   items['phone']
#       refute_nil   items['registrant_type']
#
#       # db records
#       assert_equal 1, Contact.count
#       assert_equal 1, Registrant.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#       assert Registrant.last.contactable.is_a? SslAccount
#       assert Registrant.last.organization?
#     end
#
#     it 'status 200 error: required fields are nil (organization)' do
#       req = @api_keys.merge(
#         title: 'Ms', registrant_type: Registrant::registrant_types[:organization]
#       )
#       post api_team_add_registrant_path(req)
#       items = JSON.parse(body)
#
#       # response
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 1, items.count
#       refute_nil   items['errors']
#       refute_nil   items['errors']['company_name'].first # company_name required
#       assert_nil   items['errors']['first_name']         # first and last names NOT required
#       assert_nil   items['errors']['last_name']
#       refute_nil   items['errors']['address1'].first
#       refute_nil   items['errors']['city'].first
#       refute_nil   items['errors']['state'].first
#       refute_nil   items['errors']['country'].first
#       refute_nil   items['errors']['postal_code'].first
#       refute_nil   items['errors']['email'].first
#
#       # db records
#       assert_equal 0, Contact.count
#       assert_equal 0, Registrant.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#     end
#
#     it 'status 200 error: required fields are nil (individual)' do
#       req = @api_keys.merge(
#         title: 'Ms', registrant_type: Registrant::registrant_types[:individual]
#       )
#       post api_team_add_registrant_path(req)
#       items = JSON.parse(body)
#
#       # response
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 1, items.count
#       refute_nil   items['errors']
#       assert_nil   items['errors']['company_name']     # company_name NOT required
#       refute_nil   items['errors']['first_name'].first # first and last names required
#       refute_nil   items['errors']['last_name'].first
#       refute_nil   items['errors']['address1'].first
#       refute_nil   items['errors']['city'].first
#       refute_nil   items['errors']['state'].first
#       refute_nil   items['errors']['country'].first
#       refute_nil   items['errors']['postal_code'].first
#       refute_nil   items['errors']['email'].first
#
#       # db records
#       assert_equal 0, Contact.count
#       assert_equal 0, Registrant.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#     end
#   end
# end
