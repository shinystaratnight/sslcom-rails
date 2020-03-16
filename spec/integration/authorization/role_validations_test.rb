# require 'rails_helper'
#
# describe 'validations role' do
#   before do
#     prepare_auth_tables
#
#     2.times {login_as(@validations, self.controller.cookies)}
#     visit switch_default_ssl_account_user_path(@validations.id, ssl_account_id: @owner_ssl.id)
#     @validations = User.find_by(login: 'validation_login')
#   end
#
#   describe 'tabs/index pages' do
#     it 'SHOULD permit' do
#       # users/show (Dashboard tab)
#       should_permit_path user_path(@validations)
#       # validations index (Validations tab)
#       should_permit_path validations_path
#       # teams index (Teams tab)
#       should_permit_path teams_user_path(@validations)
#       # site_seals index (Site Seals tab)
#       should_permit_path site_seals_path
#     end
#
#     it 'SHOULD NOT permit' do
#       # certificate_orders index (Order tab)
#       should_not_permit_path certificate_orders_path
#       # orders index (Transactions tab)
#       should_not_permit_path orders_path
#       # users index (Users tab)
#       should_not_permit_path users_path
#       # billing_profiles index (Billing Profiles tab)
#       should_not_permit_path billing_profiles_path(@owner_ssl.to_slug)
#     end
#   end
#
#   describe 'page and header' do
#     it 'SHOULD see' do
#       # certificate order header items
#       should_see_cert_order_headers @validations
#     end
#
#     it 'SHOULD NOT see' do
#       # CART ITEMS header item
#       should_not_see_cart_items @validations
#       # AVAILABLE FUNDS header item
#       should_not_see_available_funds @validations
#       # 'buy certificate' link
#       should_not_see_buy_certificate @validations
#       # 'api credentials' link
#       should_not_see_api_credentials @validations
#     end
#   end
#
#   describe 'teams' do
#     before {visit teams_user_path(@validations)}
#
#     it 'should have correct details' do
#       page.must_have_content "[:owner] $0.00 [orders (0)] [transactions (0)] [validations (0)] [users (1)] #{Date.today.strftime('%b')}", count: 1
#       page.must_have_content "[:validations] $0.00 [validations (0)] #{Date.today.strftime('%b')}", count: 1
#     end
#   end
#
#   describe 'site seals' do
#     before do
#       login_as(@owner, self.controller.cookies)
#       prepare_certificate_orders @validations
#       co_state_issued
#       login_as(@validations, self.controller.cookies)
#     end
#
#     it 'SHOULD NOT see' do
#       visit certificate_order_site_seal_path(
#         @validations.ssl_account.to_slug, CertificateOrder.first.ref
#       )
#       # site seal JS code
#       should_not_see_site_seal_js
#     end
#   end
#
#   describe 'certificate orders' do
#     before do
#       login_as(@owner, self.controller.cookies)
#       prepare_certificate_orders @owner
#       login_as(@validations, self.controller.cookies)
#     end
#
#     it 'SHOULD NOT permit' do
#       assert_equal           1, CertificateOrder.count
#       should_not_permit_path certificate_orders_path(@owner_ssl.to_slug)
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
#       should_not_permit_path edit_managed_user_path(@ssl_slug, @users_manager.id)
#       should_not_permit_path edit_managed_user_path(@ssl_slug, @validations.id)
#       should_not_permit_path edit_managed_user_path(@ssl_slug, @installer.id)
#       should_not_permit_path edit_managed_user_path(@ssl_slug, @account_admin.id)
#       should_not_permit_path edit_managed_user_path(@ssl_slug, @owner.id)
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
