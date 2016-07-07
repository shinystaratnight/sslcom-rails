Given /\Athe (?:admin )?user with username ['"]([^'"]*)['"] and password ['"]([^'"]*)['"] is logged in\z/ do |username, password|
  goto login_path
  Then "he logs in with username '#{username}' and password '#{password}'"
end

Given /\Athe user with username ['"]([^'"]*)['"] and password ['"]([^'"]*)['"] with role ['"]([^'"]*)['"] is logged in\z/ do |username, password, role|
  goto login_path
  Given "he logs in with username '#{username}' and password '#{password}'"
    And "'user #{username}'\'s role 'is' '#{role}'"
end

Given /\A(?:he|she|I) go(?:es)? to route path ['|"]([^'"]*)['|"]\z/ do |path|
  goto eval(path)
end

Given /\A(?:he|she|I) logs? in with username ['"]([^'"]*)['"] and password ['"]([^'"]*)['"]\z/ do |username, password|
  Given "I go to route path 'login_path'"
  fill_text "user_session_login", username
  fill_text "user_session_password", password
  Given "I click the submit image button"
end

Given /\A(?:he|she|I) (?:am|are) not logged in\z/ do
  if is_capybara?
    visit(logout_path)
  else
    @browser.goto APP_URL + logout_path
  end
end

When /\A(?:he|she|I) logs? out\z/ do
  steps %Q{Given I am not logged in}
end

When /\A(?:he|she|I) visit (.*)\z/ do |url|
  visit url
end

Then /\A(?:he|she|I) should be (?:directed to|at) path ['|"]([^'"]*)['|"]\z/ do |text|
  url_should_include(text)
end

Then /\A(?:he|she|I) should be (?:directed to|at) route path "([^\"]*)"\z/ do |text|
  url_should_include(eval(text))
end

Then /\A(?:he|she|I) should be (?:directed to|at) the login path\z/ do
  url_should_include(login_path)
end

Then /\A(?:he|she|I) should be (?:directed to|at) the order page\z/ do
  @order = Order.first
  url_should_include(order_path(@order))
end

Then /\A(?:he|she|I) should be (?:directed to|at) the certificate order page\z/ do
  url_should_include(certificate_order_path(CertificateOrder.first))
end

Then /\A(?:he|she|I) should be (?:directed to|at) the edit certificate order page\z/ do
  url_should_include(edit_certificate_order_path(CertificateOrder.first))
end

Then /\A(?:he|she|I) should be (?:directed to|at) the edit contacts page\z/ do
  url_should_include(certificate_content_contacts(CertificateContent.last))
end
