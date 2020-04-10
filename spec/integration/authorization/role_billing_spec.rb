# require 'rails_helper'
#
# describe 'billing role' do
#   before do
#     prepare_auth_tables
#
#     2.times {login_as(@billing, self.controller.cookies)}
#     visit switch_default_ssl_account_user_path(@billing.id, ssl_account_id: @owner_ssl.id)
#     @billing = User.find_by(login: 'billing_login')
#   end
#
#   describe 'tabs/index pages' do
#     it 'SHOULD permit' do
#       # certificate_orders index (Order tab), only 'renew' status certificate orders
#       should_permit_path certificate_orders_path
#       # orders index (Transactions tab)
#       should_permit_path orders_path
#       # users/show (Dashboard tab)
#       should_permit_path user_path(@billing)
#       # billing_profiles index (Billing Profiles tab)
#       should_permit_path billing_profiles_path(@owner_ssl.to_slug)
#       # teams index (Teams tab)
#       should_permit_path teams_user_path(@billing)
#     end
#
#     it 'SHOULD NOT permit' do
#       # validations index (Validations tab)
#       should_not_permit_path validations_path
#       # site_seals index (Site Seals tab)
#       should_not_permit_path site_seals_path
#       # users index (Users tab)
#       should_not_permit_path users_path
#     end
#   end
#
#   describe 'page and header' do
#     it 'SHOULD see' do
#       # CART ITEMS header item
#       should_see_cart_items @billing
#       # AVAILABLE FUNDS header item
#       should_see_available_funds @billing
#       # 'buy certificate' link
#       should_see_buy_certificate @billing
#
#     end
#     it 'SHOULD NOT see' do
#       # 'api credentials' link
#       should_not_see_api_credentials @billing
#       # certificate order header items
#       should_not_see_cert_order_headers @billing
#     end
#   end
#
#   describe 'teams' do
#     before {visit teams_user_path(@billing)}
#
#     it 'should have correct details' do
#       page.must_have_content "[:owner] $0.00 [orders (0)] [transactions (0)] [validations (0)] [users (1)] #{Date.today.strftime('%b')}", count: 1
#       page.must_have_content "[:billing] $0.00 [orders (0)] [transactions (0)] #{Date.today.strftime('%b')}", count: 1
#     end
#   end
#
#   describe 'certificate orders' do
#     before do
#       login_as(@owner, self.controller.cookies)
#       prepare_certificate_orders @owner
#       co_state_issued
#       co_state_expire
#       login_as(@billing, self.controller.cookies)
#     end
#
#     it 'SHOULD see' do
#       # 'renew' links
#       should_see_renew_link
#     end
#
#     it 'SHOULD NOT see' do
#       visit certificate_orders_path
#
#       # certificate download table
#       should_not_see_cert_download_table
#
#       # 'change domain(s)/rekey' links
#       should_not_see_reprocess_link
#
#       # certificate order content/links
#       refute page.has_content? 'seal'
#       refute page.has_content? 'details'
#       refute page.has_content? 'documents'
#       find('a.expand').click
#       refute page.has_content? 'view certificate details'
#
#       # submit csr
#       should_not_permit_path edit_certificate_order_path(@owner_ssl.to_slug, CertificateOrder.first)
#     end
#   end
#
#   describe 'users' do
#     before do
#       visit users_path
#       @ssl_slug    = @owner_ssl.to_slug
#       @total_users = @owner_ssl.users.count
#     end
#
#     it 'SHOULD NOT permit' do
#       # edit user
#       should_not_permit_path edit_managed_user_path(@ssl_slug, @billing.id)
#       should_not_permit_path edit_managed_user_path(@ssl_slug, @account_admin.id)
#       should_not_permit_path edit_managed_user_path(@ssl_slug, @owner.id)
#       should_not_permit_path edit_managed_user_path(@ssl_slug, @users_manager.id)
#       should_not_permit_path edit_managed_user_path(@ssl_slug, @validations.id)
#       should_not_permit_path edit_managed_user_path(@ssl_slug, @installer.id)
#
#       # remove any user from team
#       should_not_permit_path remove_from_account_managed_user_path(@owner_ssl, @owner.id)
#       should_not_permit_path remove_from_account_managed_user_path(@owner_ssl, @billing.id)
#       should_not_permit_path remove_from_account_managed_user_path(@owner_ssl, @account_admin.id)
#       should_not_permit_path remove_from_account_managed_user_path(@owner_ssl, @users_manager.id)
#       should_not_permit_path remove_from_account_managed_user_path(@owner_ssl, @validations.id)
#       should_not_permit_path remove_from_account_managed_user_path(@owner_ssl, @installer.id)
#       assert_equal @total_users, @owner_ssl.users.count
#     end
#   end
# end
