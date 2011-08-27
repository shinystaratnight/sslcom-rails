Given /^(?:he|she|I) adds? some items to the cart/ do
  Given "I add these items to the cart", table(%{
          |item      |price    |cart_quantity|
          |release_45|$6.99 USD|1            |
          |release_39|$9.99 USD|2            |
          |release_40|$4.99 USD|3            |
  })
end

Given /^(?:he|she|I) adds? these items to the cart/ do |products|
  @total = "12"
  Given "I click the 'link' with 'Recent Releases' 'text'"
    products.hashes.each do |product|
      When "I click the 'button' with \'#{product[:item]}\' 'id'"
      Then "I should see \'#{product[:cart_quantity]}\' in 'cart_size'"
    end
end

Given /^there is an empty shopping cart$/ do
  When "I click the 'link' with 'cart_size' 'id'"
    And "I click the 'button' with 'empty_cart' 'id'"
  Then "I should be at path '/orders/show_cart/current'"
    And "I should see 'Total'"
    And "I should see '$0.00' in 'cart_total'"
end

When /^['"]([^'"]*)['"] makes a deposit$/ do |person, profiles|
  profiles.hashes.each do |profile|
    Given "he clicks the 'link' with 'Load Funds'"
      And "he should be at path 'secure/allocate_funds'"
    When "he clicks the 'link' with 'Click here to add a new credit card'"
      And "he enters his profile information", profile
      And "he enters his credit card payment information", profile
    lambda {
        And "he clicks the submit button"
    }.should change {User.find_by_login_slug(person).
        funded_account.cents}.by(profile[:amount].delete("$.,").to_i)
  end
end

When /^(?:he|she|I) visits?\b "([^"]*)"$/ do |path|
  @browser.goto APP_URL + path
end

When /^(?:he|she|I) visits?\b the payment page$/ do
  @browser.goto APP_URL + billing_profiles_path(:new)
end
          
When /^(?:he|she|I) enters? (?:his|her|my) profile information$/ do |table|
  profiles = (defined? table.hashes) ? table.hashes : [table]
  profiles.each do |profile|
    @browser.text_field(:id, "billing_profile_first_name").value = profile["first_name"]
    @browser.text_field(:id, "billing_profile_last_name").value = profile["last_name"]
    @browser.text_field(:id, "billing_profile_address_1").value = profile["address1"]
    @browser.text_field(:id, "billing_profile_address_2").value = profile["address2"]
    @browser.text_field(:id, "billing_profile_city").value = profile["city"]
    @browser.text_field(:id, "billing_profile_state").value = profile["state"]
    @browser.text_field(:id, "billing_profile_postal_code").value = profile["postal_code"]
    @browser.select_list(:id, "billing_profile_country").set profile["country"]
    @browser.text_field(:id, "billing_profile_phone").value = profile["phone"]
  end
end

When /^(?:he|she|I) enters? (?:his|her|my) credit card payment information$/ do |table|
  cards = (defined? table.hashes) ? table.hashes : [table]
  cards.each do |card|
    @browser.select_list(:id, "billing_profile_credit_card").value = card["card_type"]
    @browser.text_field(:id, "billing_profile_card_number").value = card["card_number"]
    @browser.select_list(:id, "billing_profile_expiration_month").value = card["exp_mo"]
    @browser.select_list(:id, "billing_profile_expiration_year").value = card["exp_yr"]
    @browser.text_field(:id, "billing_profile_security_code").value = card["security_code"]
  end
end

When /^(\w*) has a new dv certificate order at the validation prompt stage$/ do |login|
  @user = User.find_by_login(login)
  @certificate_order = FactoryGirl.create(:dv_certificate_order,
    workflow_state: "new", ssl_account: @user.ssl_account)
  @certificate_content = FactoryGirl.create(:certificate_content_w_contacts,
    certificate_order: @certificate_order)
  @certificate_order.certificate_contents << @certificate_content
  @user.ssl_account.certificate_orders << @certificate_order
end

