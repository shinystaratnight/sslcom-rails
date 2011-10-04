Given /^the (?:admin )?user with username ['"]([^'"]*)['"] and password ['"]([^'"]*)['"] is logged in$/ do |username, password|
  goto login_path
  Then "he logs in with username '#{username}' and password '#{password}'"
end

Given /^the user with username ['"]([^'"]*)['"] and password ['"]([^'"]*)['"] with role ['"]([^'"]*)['"] is logged in$/ do |username, password, role|
  goto login_path
  Given "he logs in with username '#{username}' and password '#{password}'"
    And "'user #{username}'\'s role 'is' '#{role}'"
end

Given /^(?:he|she|I) go(?:es)? to route path ['|"]([^'"]*)['|"]$/ do |path|
  goto eval(path)
end

Given /^(?:he|she|I) logs? in with username ['"]([^'"]*)['"] and password ['"]([^'"]*)['"]$/ do |username, password|
  Given "I go to route path 'login_path'"
  fill_text "user_session_login", username
  fill_text "user_session_password", password
  Given "I click the submit image button"
end

Given /^(?:he|she|I) (?:am|are) not logged in$/ do
  if is_capybara?
    visit(logout_path)
  else
    @browser.goto APP_URL + logout_path
  end
end

When /^(?:he|she|I) logs? out$/ do
  steps %Q{Given I am not logged in}
end

When /^(?:he|she|I) visit (.*)$/ do |url|
  visit url
end

Then /^(?:he|she|I) should be (?:directed to|at) path ['|"]([^'"]*)['|"]$/ do |text|
  url_should_include(text)
end

Then /^(?:he|she|I) should be (?:directed to|at) route path "([^\"]*)"$/ do |text|
  url_should_include(eval(text))
end

Then /^(?:he|she|I) should be (?:directed to|at) the login path$/ do
  url_should_include(login_path)
end

Then /^(?:he|she|I) should be (?:directed to|at) the order page$/ do
  @order = Order.first
  url_should_include(order_path(@order))
end

Then /^(?:he|she|I) should be (?:directed to|at) the certificate order page$/ do
  url_should_include(certificate_order_path(CertificateOrder.first))
end

Then /^(?:he|she|I) should be (?:directed to|at) the edit certificate order page$/ do
  url_should_include(edit_certificate_order_path(CertificateOrder.first))
end

Then /^(?:he|she|I) should be (?:directed to|at) the edit contacts page$/ do
  url_should_include(certificate_content_contacts(CertificateContent.last))
end
