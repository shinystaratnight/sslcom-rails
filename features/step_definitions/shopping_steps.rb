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
  goto path
end

When /^(?:he|she|I) visits?\b the payment page$/ do
  goto billing_profiles_path(:new)
end
          
When /^(?:he|she|I) enters? (?:his|her|my) profile information$/ do |table|
  profiles = (defined? table.hashes) ? table.hashes : [table]
  profiles.each do |profile|
    {"billing_profile_first_name"=>profile["first_name"],
    "billing_profile_last_name"=>profile["last_name"],
    "billing_profile_address_1"=>profile["address1"],
    "billing_profile_address_2"=>profile["address2"],
    "billing_profile_city"=>profile["city"],
    "billing_profile_state"=>profile["state"],
    "billing_profile_postal_code"=>profile["postal_code"],
    "billing_profile_country"=>profile["country"],
    "billing_profile_phone"=>profile["phone"]}.each do |k,v|
      fill_text(k,v)
    end
  end
end

When /^(?:he|she|I) enters? (?:his|her|my) credit card payment information$/ do |table|
  cards = (defined? table.hashes) ? table.hashes : [table]
  cards.each do |card|
    {"billing_profile_credit_card"=>card["card_type"],
    "billing_profile_card_number"=>card["card_number"],
    "billing_profile_expiration_month"=>card["exp_mo"],
    "billing_profile_expiration_year"=>card["exp_yr"],
    "billing_profile_security_code"=>card["security_code"]}.each do |k,v|
      fill_text(k,v)
    end
  end
end

Given /^(\w*) has a new dv certificate order at the validation prompt stage$/ do |login|
  @user = User.find_by_login(login)
  @certificate_order = FactoryGirl.create(:new_dv_certificate_order,
    ssl_account: @user.ssl_account)
  @certificate_content = FactoryGirl.create(:certificate_content_w_contacts,
    certificate_order: @certificate_order)
end

Given /^(\w*) has a completed but unvalidated dv certificate order$/ do |login|
  @user = User.find_by_login(login)
  @certificate_order = FactoryGirl.create(:completed_unvalidated_dv_certificate_order,
    ssl_account: @user.ssl_account)
  @certificate_content = FactoryGirl.create(:certificate_content_pending_validation,
    certificate_order: @certificate_order)
end
