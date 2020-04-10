# require 'rails_helper'
# #
# # A valid logged-in user makes a certificate order purchase using
# # a valid credit card.
# #
# describe 'Valid user' do
#   before do
#     create(:certificate, :basicssl)
#     @logged_in_user     = create(:user, :owner)
#     @logged_in_ssl_acct = @logged_in_user.ssl_account
#     @logged_in_ssl_acct.billing_profiles << create(:billing_profile)
#     @billing_profile    = @logged_in_ssl_acct.billing_profiles.first
#     @year_3_id          = ProductVariantItem.find_by(serial: "sslcombasic256ssl3yr").id
#     @amount             = '$156.21'
#     login_as(@logged_in_user, self.controller.cookies)
#
#     assert_equal 1, BillingProfile.count
#     assert_equal 1, FundedAccount.count
#     assert_equal 0, ShoppingCart.count
#
#     visit buy_certificate_path 'basicssl'
#     find("#product_variant_item_#{@year_3_id}").click # 3 Years $52.07/yr
#     page.must_have_content @amount # $52.07 * 3 years
#
#     # Shopping Cart
#     find('#next_submit input').click
#     page.must_have_content @amount
#
#     # Checkout
#     click_on 'Checkout'
#     page.must_have_content('Funding Sources')
#     page.must_have_content(@billing_profile.last_digits)
#     page.must_have_content("Order Amount: charged in $USD #{@amount} USD")
#     find("#funding_source_#{BillingProfile.first.id}").click
#     find('input[name="next"]').click
#     sleep 2 # allow time to generate notification email
#   end
#   it 'creates correct records and renders correct elements in view' do
#     # user receives #certificate_order_prepaid notification email
#     # ======================================================
#       assert_equal    1, email_total_deliveries
#       assert_includes email_subject, Order.first.reference_number
#       assert_match    @logged_in_user.email, email_to
#       assert_match    'orders@ssl.com', email_from
#       assert_includes email_body, "Order Amount: #{@amount}"
#
#     # creates database records
#     # ======================================================
#       assert_equal 1, Order.count
#       assert_equal 1, OrderTransaction.count
#       assert_equal 1, CertificateOrder.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 1, LineItem.count
#       assert_equal 1, OrderTransaction.count
#       assert_equal 1, ShoppingCart.count
#
#     # creates correct order record
#     # ======================================================
#       o = Order.first
#       assert_equal @billing_profile.id, o.billing_profile_id
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
#       assert_equal @logged_in_ssl_acct.id, co.ssl_account_id
#       assert_equal 'paid', co.workflow_state
#       assert_equal 1, co.line_item_qty
#       assert_equal 15621, co.amount
#
#     # show order transaction page
#     # ======================================================
#       # Shopping cart is empty and belongs to user
#       assert_equal User.first.id, ShoppingCart.first.user_id
#       assert_nil   ShoppingCart.first.content
#
#       page.must_have_content 'Show Order Transaction'
#       page.must_have_content Order.first.reference_number
#       page.must_have_content "date of order: #{Order.first.created_at.strftime('%Y-%m-%d')}"
#       page.must_have_content @billing_profile.last_digits
#       page.must_have_content @amount
#   end
# end
#
#
