# require 'rails_helper'
#
# class SavedContactsTest < ActionDispatch::IntegrationTest
#   describe 'saved_contacts' do
#     before do
#       api_min_setup
#     end
#
#     it 'status 200: 2 contacts exist' do
#       c_params   = @api_keys.merge(api_get_contact)
#       post api_team_add_contact_path(c_params)
#       post api_team_add_contact_path(c_params.merge(
#         company_name: 'Test Company', first_name: 'Test', last_name: 'Contact'
#       ))
#       assert_equal 0, Registrant.count
#       assert_equal 2, CertificateContact.count
#       assert_equal 2, Contact.count
#
#       get api_team_saved_contacts_path(@api_keys)
#       items = JSON.parse(body)
#
#       # response
#       contact_ids = CertificateContact.pluck(:id)
#       items['data'].each do |body|
#         assert match_response_schema('team_saved_contacts', body.to_json) # json schema
#         assert contact_ids.include? body['id'].to_i
#         item = body['attributes']
#         assert_match 'CertificateContact', body['type']
#         if body['registrant_type']=='organization'
#           refute_nil   item['company_name']
#         end
#         refute_nil   item['first_name']
#         refute_nil   item['last_name']
#         assert_nil   item['po_box']
#         refute_nil   item['address1']
#         refute_nil   item['city']
#         refute_nil   item['state']
#         refute_nil   item['country']
#         refute_nil   item['postal_code']
#         refute_nil   item['email']
#         refute_nil   item['phone']
#       end
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 2, items['data'].count
#     end
#
#     it 'status 200: empty list' do
#       assert_equal 0, Registrant.count
#       assert_equal 0, CertificateContact.count
#       assert_equal 0, Contact.count
#
#       get api_team_saved_registrants_path(@api_keys)
#       items = JSON.parse(body)
#
#       # response
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 0, items['data'].count
#     end
#   end
# end
