Given /^the (?:admin )?user with username ['"]([^'"]*)['"] and password ['"]([^'"]*)['"] is logged in$/ do |username, password|
  @browser.goto APP_URL + login_path
  Then "he logs in with username '#{username}' and password '#{password}'"
end

Given /^the user with username ['"]([^'"]*)['"] and password ['"]([^'"]*)['"] with role ['"]([^'"]*)['"] is logged in$/ do |username, password, role|
  @browser.goto APP_URL + login_path
  Given "he logs in with username '#{username}' and password '#{password}'"
    And "'user #{username}'\'s role 'is' '#{role}'"
end

Given /^(?:he|she|I) go(?:es)? to route path ['|"]([^'"]*)['|"]$/ do |path|
  @browser.goto APP_URL + eval(path)
end

Given /^(?:he|she|I) logs? in with username ['"]([^'"]*)['"] and password ['"]([^'"]*)['"]$/ do |username, password|
  Given "I go to route path 'login_path'"
  @browser.text_field(:id, "user_session_login").value= username
  @browser.text_field(:id, "user_session_password").value= password
  Given "I click the submit image button"
end

Given /^(?:he|she|I) (?:am|are) not logged in$/ do
  @browser.goto APP_URL + logout_path
end

When /^(?:he|she|I) logs? out$/ do
  steps %Q{Given I am not logged in}
end

When /^(?:he|she|I) visit (.*)$/ do |url|
  visit url
end

Then /^(?:he|she|I) should be (?:directed to|at) path ['|"]([^'"]*)['|"]$/ do |text|
  @browser.url.should include(text)
end

Then /^(?:he|she|I) should be (?:directed to|at) route path "([^\"]*)"$/ do |text|
  @browser.url.should include(eval(text))
end

Then /^(?:he|she|I) should be directed to the login path$/ do
  @browser.url.should include(login_path)
end

Then /^(?:he|she|I) should be directed to the order page$/ do
  @order = Order.last
  @browser.url.should include(order_path(@order))
end