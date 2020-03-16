# require 'rails_helper'
#
# class AddContactTest < ActionDispatch::IntegrationTest
#   describe 'add_contact' do
#     before do
#       api_min_setup
#       assert_equal 0, InvalidApiCertificateRequest.count
#     end
#
#     it 'status 200: valid contact' do
#       req = @api_keys.merge(api_get_contact)
#
#       post api_team_add_contact_path(req)
#       items = JSON.parse(body)
#
#       # response
#       assert       match_response_schema('team_valid_contact') # json schema
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 17, items.count
#       assert_nil   items['title']
#       refute_nil   items['first_name']
#       refute_nil   items['last_name']
#       refute_nil   items['last_name']
#       assert_nil   items['po_box']
#       refute_nil   items['address1']
#       refute_nil   items['city']
#       refute_nil   items['state']
#       refute_nil   items['country']
#       refute_nil   items['postal_code']
#       refute_nil   items['email']
#       refute_nil   items['phone']
#
#       # db records
#       assert_equal 1, Contact.count
#       assert_equal 1, CertificateContact.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#       assert CertificateContact.last.contactable.is_a? SslAccount
#       assert CertificateContact.last.roles.empty?
#     end
#
#     it 'status 200 error: required fields are nil' do
#       req = @api_keys.merge(title: 'Ms')
#
#       post api_team_add_contact_path(req)
#       items = JSON.parse(body)
#
#       # response
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 1, items.count
#       refute_nil   items['errors']
#       refute_nil   items['errors']['first_name'].first
#       refute_nil   items['errors']['last_name'].first
#       refute_nil   items['errors']['email'].first
#       refute_nil   items['errors']['phone'].first
#
#       # db records
#       assert_equal 0, Contact.count
#       assert_equal 0, CertificateContact.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#     end
#   end
# end
