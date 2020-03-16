# require 'rails_helper'
#
# describe 'add domains to shopping cart' do
#   before do
#     initialize_roles
#     initialize_certificates
#     initialize_server_software
#     initialize_certificate_csr_keys
#
#     @logged_in_user = create(:user, :owner)
#     @logged_in_ssl_acct = @logged_in_user.ssl_account
#     @logged_in_ssl_acct.billing_profiles << create(:billing_profile)
#
#     login_as(@logged_in_user, self.controller.cookies)
#
#     @main_id = 'certificate_order_certificate_contents_attributes_0'
#     @first_domains_group = 'api1.sunnyweatherdom.com api2.sunnyweatherdom.com api3.sunnyweatherdom.com'
#     @second_domains_group =
#         'api4.sunnyweatherdom.com api5.sunnyweatherdom.com api6.sunnyweatherdom.com api7.sunnyweatherdom.com api8.sunnyweatherdom.com api9.sunnyweatherdom.com'
#   end
#
#   it 'One Item what has 3 domains in shopping cart' do
#     # Visit /certificates/evucc/buy page
#     visit buy_certificate_path "evucc"
#
#     # Choose 1 Year for Duration
#     find("#certificate_order_duration_1").click
#     # Add domains
#     fill_in "#{@main_id}_additional_domains", with: @first_domains_group
#
#     # Form Submit
#     page.execute_script("jQuery('form').submit();")
#     # Check Whether Shopping cart page has been opened or not
#     @first_domains_group.split.each {|domain| page.must_have_content domain}
#
#     # Get Shopping cart data from Database
#     sc = ShoppingCart.first
#     # Get Content from Shopping cart data
#     content = JSON.parse(sc.content)
#
#     # Compare Item counts in Shopping Cart
#     assert_equal 1, content.size
#     # Compare Domains counts of First Item in Shopping Cart
#     assert_equal 3, content[0]['do'].split(' ').size
#   end
#
#   it 'Two Items what first item has 3 domains and second item has 5 domains in shopping cart' do
#     # ================================= First Item =================================
#     # Visit /certificates/evucc/buy page
#     visit buy_certificate_path "evucc"
#
#     # Choose 1 Year for Duration
#     find("#certificate_order_duration_1").click
#     # Add domains
#     fill_in "#{@main_id}_additional_domains", with: @first_domains_group
#
#     # Form Submit
#     page.execute_script("jQuery('form').submit();")
#     # Check Whether Shopping cart page has been opened or not
#     @first_domains_group.split.each {|domain| page.must_have_content domain}
#
#     # ================================= Second Item =================================
#     # Visit /certificates/evucc/buy page
#     visit buy_certificate_path "evucc"
#
#     # Choose 1 Year for Duration
#     find("#certificate_order_duration_1").click
#     # Add domains
#     fill_in "#{@main_id}_additional_domains", with: @second_domains_group
#
#     # Form Submit
#     page.execute_script("jQuery('form').submit();")
#     # Check Whether Shopping cart page has been opened or not
#     @second_domains_group.split.each {|domain| page.must_have_content domain}
#
#     # Get Shopping cart data from Database
#     sc = ShoppingCart.first
#     # Get Content from Shopping cart data
#     content = JSON.parse(sc.content)
#
#     # Compare Item counts in Shopping Cart
#     assert_equal 2, content.size
#     # Compare Domains counts of First Item in Shopping Cart
#     assert_equal 3, content[0]['do'].split(' ').size
#     # Compare Domains counts of Second Item in Shopping Cart
#     assert_equal 6, content[1]['do'].split(' ').size
#   end
# end
