# require 'rails_helper'
#
# class ApiUserRequestsControllerTest < ActionDispatch::IntegrationTest
#   describe 'api_user_show_v1_4' do
#     before do
#       set_api_host
#       initialize_roles
#       @user = create(:user, :owner)
#       @team = @user.ssl_account
#       assert @user.valid?
#     end
#
#     it 'status 200' do
#       get api_user_show_v1_4_path(@user.login, password: @user.password)
#       items = JSON.parse(body)
#
#       assert       response.success?
#       assert       match_response_schema('user_show')
#       assert_equal 200, status
#       assert_equal 8, items.count
#       assert_match @user.login, items['login']
#       assert_match @user.email, items['email']
#       assert_match @user.status, items['status']
#       assert_match @team.acct_number, items['account_number']
#       assert_match @team.api_credential.account_key, items['account_key']
#       assert_match @team.api_credential.secret_key, items['secret_key']
#       assert_match "https://#{Settings.portal_domain}/users/#{@user.id}", items['user_url']
#       assert_match Money.new(@team.funded_account.cents).format, items['available_funds']
#     end
#
#     it 'status 200: login error' do
#       get api_user_show_v1_4_path('fake', password: 'fake@password1')
#       items = JSON.parse(body)
#
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 1, items.count
#       refute_nil   items['errors']
#       refute_nil   items['errors']['login']
#       assert_equal items['errors']['login'], ['fake not found or incorrect password']
#     end
#   end
#
#   describe 'create_v1_4' do
#     before do
#       set_api_host
#       initialize_roles
#       assert_equal 0, User.count
#     end
#
#     it 'status 200' do
#       request = {
#         login:    'ssl_demo',
#         email:    'api@ssl.com',
#         password: '!Ss1_c3Rt$'
#       }
#       post api_user_create_v1_4_path(request)
#       items = JSON.parse(body)
#       user  = User.first
#       cred  = user.ssl_account.api_credential
#
#       assert       response.success?
#       assert       match_response_schema('user_created')
#       assert_equal 200, status
#       assert_equal 5, items.count
#       assert_equal 1, User.count
#       assert_equal 1, user.assignments.count
#       assert_equal user.ssl_account.id, user.assignments.first.ssl_account_id
#       assert_match user.status, items['status']
#       assert_match user.ssl_account.acct_number, items['account_number']
#       assert_match cred.account_key, items['account_key']
#       assert_match cred.secret_key, items['secret_key']
#     end
#
#     it 'status 200: password error' do
#       request = {
#         login:    'ssl_demo',
#         email:    'api@ssl.com',
#         password: 'invalid'
#       }
#       post api_user_create_v1_4_path(request)
#       items = JSON.parse(body)
#
#       assert       response.success?
#       assert_equal 200, status
#       assert_equal 1, items.count
#       refute_nil   items['errors']
#       refute_nil   items['errors']['password']
#     end
#   end
# end
