# require 'rails_helper'
# #
# # A valid logged-in user makes a certificate order purchase using
# # Paypal.
# #
# describe 'Valid user' do
#   before do
#     initialize_roles
#     initialize_certificates
#     @logged_in_user     = create(:user, :owner)
#     @logged_in_ssl_acct = @logged_in_user.ssl_account
#     @logged_in_ssl_acct.billing_profiles << create(:billing_profile)
#     @billing_profile    = @logged_in_ssl_acct.billing_profiles.first
#     @year_3_id          = ProductVariantItem.find_by(serial: "sslcombasic256ssl3yr").id
#     login_as(@logged_in_user, self.controller.cookies)
#     @funded_account     = @logged_in_ssl_acct.funded_account
#     @amount             = '$156.21'
#
#     # Add any funds to funded account so Paypal displays as option.
#     @funded_account.cents = 600
#     @funded_account.save
#
#     assert_equal 1, BillingProfile.count
#     assert_equal 1, FundedAccount.count
#     assert_equal 0, ShoppingCart.count
#
#     # Buy Certificate
#     visit buy_certificate_path 'basicssl'
#     find("#product_variant_item_#{@year_3_id}").click # 3 Years $52.07/yr
#     page.must_have_content "#{@amount} USD" # $52.07 * 3 years
#
#     # Shopping Cart
#     find('#next_submit input').click
#     page.must_have_content "#{@amount} USD"
#
#     # Checkout
#     click_on 'Checkout'
#     page.must_have_content('Funding Sources')
#     page.must_have_content('Paypal')
#     page.must_have_content(@billing_profile.last_digits)
#     page.must_have_content("Order Amount: charged in $USD #{@amount} USD")
#     find("#funded_account_funding_source_paypal").click
#     find('img[title="paypal"]').click
#
#     # Paypal Gateway page
#     page.must_have_content '$150.21 USD'
#     paypal_login
#   end
#
#   it 'creates correct records and view' do
#     @co = Order.find_by(description: 'SSL Certificate Order')
#     @pd = Order.find_by(description: 'Paypal Deposit')
#     @fa = Order.find_by(description: 'Funded Account Withdrawal')
#
#     # user receives #certificate_order_prepaid notification email
#     # ======================================================
#       assert_equal    1, email_total_deliveries
#       assert_includes email_subject, @co.reference_number
#       assert_match    @logged_in_user.email, email_to
#       assert_match    'orders@ssl.com', email_from
#       assert_includes email_body, "Order Amount: #{@amount}"
#
#     # creates database records
#     # ======================================================
#       assert_equal 3, Order.count
#       assert_equal 2, Deposit.count # For Paypal Deposit and Funded Account Withdrawal
#       assert_equal 0, OrderTransaction.count # only for CC purchase
#       assert_equal 1, CertificateOrder.count
#       assert_equal 1, CertificateContent.count
#       assert_equal 3, LineItem.count
#       assert_equal 1, ShoppingCart.count
#
#     # creates correct line_items associated w/3 orders
#     # ======================================================
#       ssl_cert_line_items = @co.line_items.first
#       paypal_line_item    = @pd.line_items.first
#       funded_acct_item    = @fa.line_items.first
#
#       # CertificateOrder           $156.43
#       # Funded Account Credit     -$6.00    (Order w/description 'Funded Account Withdrawal')
#       # - - - - - - - - - - - - - - - - -
#       # Deposit                    $150.43  (After credit, remaining $ for payment)
#
#       assert_equal @co.id, ssl_cert_line_items.order_id
#       assert_equal 'CertificateOrder', ssl_cert_line_items.sellable_type
#       assert_equal 15621, ssl_cert_line_items.cents
#
#       assert_equal @pd.id, paypal_line_item.order_id
#       assert_equal 'Deposit', paypal_line_item.sellable_type
#       assert_equal 15021, paypal_line_item.cents
#
#       assert_equal @fa.id, funded_acct_item.order_id
#       assert_equal 'Deposit', funded_acct_item.sellable_type
#       assert_equal 600, funded_acct_item.cents
#
#     # creates correct order records
#     # ======================================================
#       assert_equal 'SslAccount', @co.billable_type
#       assert_equal 'paid', @co.state
#       assert_equal 'active', @co.status
#       assert_equal 15621, @co.cents
#       refute_nil   @co.reference_number
#       assert_nil   @co.billing_profile_id # not using CC
#
#       assert_equal    'SslAccount', @pd.billable_type
#       assert_equal    'paid', @pd.state
#       assert_equal    'active', @pd.status
#       refute_nil      @pd.reference_number
#       assert_includes @pd.notes, 'paidviapaypal'
#
#     # creates correct certificate order record
#     # ======================================================
#       co = CertificateOrder.first
#       assert_equal @logged_in_ssl_acct.id, co.ssl_account_id
#       assert_equal 'paid', co.workflow_state
#       assert_equal 1, co.line_item_qty
#       assert_equal 15621, co.amount
#
#     # Shopping cart is empty and belongs to user
#     # ======================================================
#       assert_equal 1, ShoppingCart.count
#       assert_equal User.first.id, ShoppingCart.first.user_id
#       assert_nil   ShoppingCart.first.content
#
#     # orders history page
#     # ======================================================
#       page.must_have_content('SSL Certificate Order')
#       page.must_have_content(@co.reference_number)
#       page.must_have_content(@amount)
#
#       page.must_have_content('Paypal Deposit')
#       page.must_have_content(@pd.reference_number)
#       page.must_have_content("(#{@amount})")
#   end
# end
