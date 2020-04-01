# require 'rails_helper'
# #
# # An anonymous or guest user makes a certificate order purchase using
# # a valid credit card. End result should be a newly created user with valid
# # order and certificate order.
# #
# describe 'Anonymous user' do
#   before do
#     create(:certificate, :basicssl)
#     @year_3_id = ProductVariantItem.find_by(serial: "sslcombasic256ssl3yr").id
#     @new_email = 'new_user@ssl.com'
#     @amount    = '$156.21'
#
#     assert_equal 0, BillingProfile.count
#     assert_equal 0, FundedAccount.count
#     assert_equal 0, User.count
#     assert_equal 0, Assignment.count
#     assert_equal 0, SslAccount.count
#     assert_equal 0, SslAccountUser.count
#     assert_equal 0, ShoppingCart.count
#
#     visit buy_certificate_path 'basicssl'
#     find("#product_variant_item_#{@year_3_id}").click # 3 Years $52.07/yr
#     page.must_have_content("#{@amount} USD") # $52.07 * 3 years
#     # Shopping Cart
#     find('#next_submit input').click
#     page.must_have_content("#{@amount} USD")
#     # Checkout
#     click_on 'Checkout'
#     page.must_have_content('required fields below to complete your account registration.')
#     page.must_have_content("Order Amount: charged in $USD #{@amount} USD")
#     assert_equal 1, ShoppingCart.count
#     refute_nil   ShoppingCart.first.content
#     assert_nil   ShoppingCart.first.user_id
#
#     # Login Information
#     fill_in 'user_login',                  with: 'new_user'
#     fill_in 'user_email',                  with: @new_email
#     fill_in 'user_password',               with: @password
#     fill_in 'user_password_confirmation',  with: @password
#     # Billing Information
#     fill_in 'billing_profile_first_name',  with: 'first'
#     fill_in 'billing_profile_last_name',   with: 'last'
#     fill_in 'billing_profile_address_1',   with: '3100 Richmond Ave'
#     fill_in 'billing_profile_postal_code', with: '77098'
#     fill_in 'billing_profile_city',        with: 'Houston'
#     fill_in 'billing_profile_state',       with: 'Texas'
#     fill_in 'billing_profile_phone',       with: '7752378434'
#     select  'United States', from: 'billing_profile_country'
#     # CC Information: valid
#     select 'Visa',                           from: 'billing_profile_credit_card'
#     select '1',                              from: 'billing_profile_expiration_month'
#     select Date.today.year + 1,              from: 'billing_profile_expiration_year'
#     fill_in 'billing_profile_card_number',   with: (BillingProfile.gateway_stripe? ? '4242424242424242' : '4007000000027')
#     fill_in 'billing_profile_security_code', with: '900'
#
#     find('input[name="next"]').click
#     sleep 2 # allow time for email notifications
#   end
#
#   it 'creates correct records and renders correct elements in view' do
#     # new user receives #activation_confirmation notification email
#     # ======================================================
#       assert_equal    2, email_total_deliveries
#       assert_equal    'SSL.com user account activated', email_subject(:first)
#       assert_match    @new_email, email_to(:first)
#       assert_match    'noreply@ssl.com', email_from(:first)
#       assert_includes email_body(:first), "Your SSL.com account for username new_user has been activated."
#
#     # new user receives #certificate_order_prepaid notification email
#     # ======================================================
#       assert_equal    2, email_total_deliveries
#       assert_match    @new_email, email_to
#       assert_match    'orders@ssl.com', email_from
#       assert_includes email_subject, Order.first.reference_number
#       assert_includes email_body, "Order Amount: #{@amount}"
#
#     # creates database records
#     # ======================================================
#       sleep 1
#       assert_equal 1, User.count
#       assert_equal 1, Assignment.count
#       assert_equal 1, SslAccount.count
#       assert_equal 1, SslAccountUser.count
#       assert_equal 1, BillingProfile.count
#       assert_equal 1, FundedAccount.count
#       assert_equal 1, Order.count
#       assert_equal 1, OrderTransaction.count
#       assert_equal 1, CertificateOrder.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 1, LineItem.count
#       assert_equal 1, OrderTransaction.count
#
#     # creates correct order record
#     # ======================================================
#       o = Order.first
#       assert_equal User.first.ssl_account.billing_profiles.first.id, o.billing_profile_id
#       assert_equal 'SslAccount', o.billable_type
#       assert_equal 'paid', o.state
#       assert_equal 'active', o.status
#       assert_equal 15621, o.cents
#       assert_equal OrderTransaction.first.order_id, o.id
#       refute_nil   o.reference_number
#
#     # creates correct certificate order record
#     # ======================================================
#       co = CertificateOrder.first
#       assert_equal User.first.ssl_account.id, co.ssl_account_id
#       assert_equal 'paid', co.workflow_state
#       assert_equal 1, co.line_item_qty
#       assert_equal 15621, co.amount
#
#     # creates correct user record
#     # ======================================================
#       user = User.first
#       refute_nil   user.login_count
#       assert_equal 1, user.get_all_approved_accounts.count
#       assert_equal 1, user.assignments.count
#       assert_equal 1, user.ssl_account_users.count
#       assert_equal User.first, SslAccount.first.get_account_owner
#
#     # show order transaction page
#     # ======================================================
#       # Order show: Capybara doesn't add cookie automatically, so need to login user manually.
#       login_as(User.first, self.controller.cookies)
#       reference_number = Order.first.reference_number
#       visit order_path(SslAccount.first.ssl_slug, reference_number)
#
#       page.must_have_content(reference_number)
#       page.must_have_content('Show Order Transaction')
#       page.must_have_content("date of order: #{Order.first.created_at.strftime('%Y-%m-%d')}")
#       page.must_have_content(BillingProfile.first.last_digits)
#       page.must_have_content('$156.21')
#   end
# end
#
#
