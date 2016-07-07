Given /\A(?:he|she|I) signs? up as a reseller using login ['"]([^'"]*)['"] and email ['"]([^'"]*)['"]\z/ do |login, email|
  @browser.goto APP_URL + new_account_path
  @browser.text_field(:id, "user_login").value= login
  @browser.text_field(:id, "user_email").value= email
  @browser.button(:src, /register\.gif/).click
end

When /\A(?:he|she|I) resets? the password for email ['"]([^'"]*)['"]\z/ do |email|
  @browser.goto APP_URL + new_password_reset_path
  steps %Q{
    When I enter "#{email}" in the "email""text_field"
      And I click the submit image button
  }
end

When /\A(?:he|she|I) request a username reminder for email ['"]([^'"]*)['"]\z/ do |email|
  goto new_password_reset_path
  steps %Q{
    When I enter "#{email}" in the "email""text_field"
      And I click the submit image button
  }
end

When /\A(?:he|she|I) resets? the password for username ['"]([^'"]*)['"]\z/ do |login|
  goto new_password_reset_path
  steps %Q{
    When I enter "#{login}" in the "login""text_field"
      And I click the submit image button
  }
end

When /\A(?:he|she|I) sets? the password to ['"]([^'"]*)['"] for the account\z/ do |password|
  steps %Q{
    When I enter "#{password}" in the "text_field" with attribute "id" == "user_password"
     And I enter "#{password}" in the "text_field" with attribute "id" == "user_password_confirmation"
     And I click the next image button
  }
end

When /\A(?:he|she|I) sets? the password to ['"]([^'"]*)['"] but not the confirmation password\z/ do |password|
  steps %Q{
    When I enter "#{password}" in the "text_field" with attribute "id" == "user_password"
      And I click the submit image button
  }
end

When /\A(?:he|she|I) go(?:es)? to the activation link that was sent to ['"]([^'"]*)['"]\z/ do |email|
  confirmation = ActionMailer::Base.deliveries.first
  confirmation.from.should == "no-reply@ssl.com"
  confirmation.to.should == email
  confirmation.body.should include("Thank you for creating an account!")
end

Then /\A['"](user .+?)['"] should be an activated reseller\z/ do |user|
  user.roles.should include(Role.find_by_name(Role::RESELLER))
  user.should be_active
end


Then /\A(\S+) should be required to register\z/ do |user|
  page.has_content?("You must be logged in")
  current_path.should == new_user_session_path
end