# require 'rails_helper'
# #
# # An anonymous or guest user makes a certificate order purchase using
# # Paypal.
# #
# describe 'Valid user' do
#   before do
#     initialize_certificates
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
#     # Buy Certificate
#     visit buy_certificate_path 'basicssl'
#     find("#product_variant_item_#{@year_3_id}").click # 3 Years $52.07/yr
#     page.must_have_content("#{@amount} USD") # $52.07 * 3 years
#
#     # Shopping Cart
#     find('#next_submit input').click
#     page.must_have_content("#{@amount} USD")
#
#     # Checkout
#     click_on 'Checkout'
#     page.must_have_content('required fields below to complete your account registration.')
#     page.must_have_content("Order Amount: charged in $USD #{@amount} USD")
#     assert_equal 1, ShoppingCart.count
#     refute_nil   ShoppingCart.first.content
#     assert_nil   ShoppingCart.first.user_id
#
#     # New Login Information
#     fill_in 'user_login',                  with: 'new_user'
#     fill_in 'user_email',                  with: @new_email
#     fill_in 'user_password',               with: @password
#     fill_in 'user_password_confirmation',  with: @password
#
#     # Payment Method: Paypal checkbox
#     find('#payment_method_paypal').click
#     find('input[name="next"]').click
#
#     # Paypal Gateway page
#     page.must_have_content("#{@amount} USD")
#     paypal_login
#
#     login_as(User.first, self.controller.cookies)
#     visit orders_path
#   end
#
#   it 'creates correct records and view' do
#     @co = Order.find_by(description: 'SSL Certificate Order')
#
#     # new user receives 'activation_confirmation' notification email
#     # ======================================================
#       assert_equal    2, email_total_deliveries
#       assert_equal    'SSL.com user account activated', email_subject(:first)
#       assert_match    @new_email, email_to(:first)
#       assert_match    'noreply@ssl.com', email_from(:first)
#       assert_includes email_body(:first), "Your SSL.com account for username new_user has been activated."
#
#     # user receives #certificate_order_prepaid notification email
#     # ======================================================
#       assert_includes email_subject, @co.reference_number
#       assert_match    @new_email, email_to
#       assert_match    'orders@ssl.com', email_from
#       assert_includes email_body, "Order Amount: #{@amount}"
#
#     # creates database records
#     # ======================================================
#       assert_equal 1, User.count
#       assert_equal 1, Assignment.count
#       assert_equal 1, SslAccount.count
#       assert_equal 1, SslAccountUser.count
#       assert_equal 1, FundedAccount.count
#       assert_equal 0, BillingProfile.count   # user did not save any credit cards
#       assert_equal 1, Order.count
#       assert_equal 0, OrderTransaction.count # only for CC purchase
#       assert_equal 1, CertificateOrder.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 1, LineItem.count
#       assert_equal 1, ShoppingCart.count
#
#     # creates correct line_items associated with order
#     # ======================================================
#       ssl_cert_line_items = @co.line_items.first
#
#       assert_equal @co.id, ssl_cert_line_items.order_id
#       assert_equal 'CertificateOrder', ssl_cert_line_items.sellable_type
#       assert_equal 15621, ssl_cert_line_items.cents
#
#     # creates correct order record
#     # ======================================================
#       assert_equal 'SslAccount', @co.billable_type
#       assert_equal 'paid', @co.state
#       assert_equal 'active', @co.status
#       assert_equal 15621, @co.cents
#       refute_nil   @co.reference_number
#       assert_nil   @co.billing_profile_id        # not using CC
#       assert_includes @co.notes, 'paidviapaypal' # paid through Paypal
#
#     # creates correct certificate order record
#     # ======================================================
#       co = CertificateOrder.first
#       assert_equal User.first.id, co.ssl_account_id
#       assert_equal 'paid', co.workflow_state
#       assert_equal 1, co.line_item_qty
#       assert_equal 15621, co.amount
#
#     # orders history page
#     # ======================================================
#       page.must_have_content('SSL Certificate Order')
#       page.must_have_content(@co.reference_number)
#       page.must_have_content("(#{@amount})")
#   end
# end
