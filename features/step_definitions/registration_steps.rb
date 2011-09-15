Given /^(?:he|she|I) signs? up as a reseller using login ['"]([^'"]*)['"] and email ['"]([^'"]*)['"]$/ do |login, email|
  @browser.goto APP_URL + new_account_path
  @browser.text_field(:id, "user_login").value= login
  @browser.text_field(:id, "user_email").value= email
  @browser.button(:src, /register\.gif/).click
end

When /^(?:he|she|I) resets? the password for email ['"]([^'"]*)['"]$/ do |email|
  @browser.goto APP_URL + new_password_reset_path
  steps %Q{
    When I enter "#{email}" in the "email""text_field"
      And I click the submit image button
  }
end

When /^(?:he|she|I) request a username reminder for email ['"]([^'"]*)['"]$/ do |email|
  goto new_password_reset_path
  steps %Q{
    When I enter "#{email}" in the "email""text_field"
      And I click the submit image button
  }
end

When /^(?:he|she|I) resets? the password for username ['"]([^'"]*)['"]$/ do |login|
  goto new_password_reset_path
  steps %Q{
    When I enter "#{login}" in the "login""text_field"
      And I click the submit image button
  }
end

When /^(?:he|she|I) sets? the password to ['"]([^'"]*)['"] for the account$/ do |password|
  steps %Q{
    When I enter "#{password}" in the "text_field" with attribute "id" == "user_password"
     And I enter "#{password}" in the "text_field" with attribute "id" == "user_password_confirmation"
     And I click the next image button
  }
end

When /^(?:he|she|I) sets? the password to ['"]([^'"]*)['"] but not the confirmation password$/ do |password|
  steps %Q{
    When I enter "#{password}" in the "text_field" with attribute "id" == "user_password"
      And I click the submit image button
  }
end

When /^(?:he|she|I) go(?:es)? to the activation link that was sent to ['"]([^'"]*)['"]$/ do |email|
  confirmation = ActionMailer::Base.deliveries.first
  confirmation.from.should == "no-reply@ssl.com"
  confirmation.to.should == email
  confirmation.body.should include("Thank you for creating an account!")
end

Then /^['"](user .+?)['"] should be an activated reseller$/ do |user|
  user.roles.should include(Role.find_by_name(Role::RESELLER))
  user.should be_active
end


Then /^(\S+) should be required to register$/ do |user|
  page.has_content?("You must be logged in")
  current_path.should == new_user_session_path
end