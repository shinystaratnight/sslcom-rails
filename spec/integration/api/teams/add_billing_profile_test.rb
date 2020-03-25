# require 'rails_helper'
#
# class AddBillingProfileTest < ActionDispatch::IntegrationTest
#   describe 'add_billing_profile' do
#     before do
#       api_min_setup
#       assert_equal 0, InvalidApiCertificateRequest.count
#     end
#
#     it 'status 200: valid profile' do
#       req = @api_keys.merge(api_get_new_billing_info)
#
#       post api_team_add_billing_profile_path(req)
#       items = JSON.parse(body)
#
#       # response
#       assert       match_response_schema('team_valid_billing') # json schema
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 6, items.count
#       refute_nil   items['first_name']
#       refute_nil   items['last_name']
#       refute_nil   items['credit_card']
#       refute_nil   items['last_digits']
#       refute_nil   items['expiration_year']
#       refute_nil   items['expiration_month']
#
#       # db records
#       bp = BillingProfile.last
#       assert_equal 1, BillingProfile.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#       assert_match items['last_digits'], bp.last_digits
#       assert_equal @team, bp.ssl_account
#     end
#
#     it 'status 200 error: required fields are nil' do
#       post api_team_add_billing_profile_path(@api_keys)
#       items = JSON.parse(body)
#
#       # response
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 1, items.count
#       refute_nil   items['errors']
#       refute_nil   items['errors']['first_name'].first
#       refute_nil   items['errors']['last_name'].first
#       refute_nil   items['errors']['postal_code'].first
#       refute_nil   items['errors']['city'].first
#       refute_nil   items['errors']['state'].first
#       refute_nil   items['errors']['country'].first
#       refute_nil   items['errors']['phone'].first
#       refute_nil   items['errors']['credit_card'].first
#       refute_nil   items['errors']['card_number'].first
#       refute_nil   items['errors']['security_code'].first
#       refute_nil   items['errors']['expiration_year'].first
#       refute_nil   items['errors']['expiration_month'].first
#
#       # db records
#       assert_equal 0, BillingProfile.count
#       assert_equal 0, InvalidApiCertificateRequest.count
#     end
#   end
# end
