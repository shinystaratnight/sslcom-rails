When /^I login as (\S+)$/ do |login|
  When "I login as #{login} with #{login}pass"
end

When /^I login as (\S+) from here$/ do |login|
  When "I fill in login details with #{login} and #{login}pass"
  click_button
end

When /^I login as (\S+) with my email address$/ do |login|
  When "I login as #{User.find_by_login(login).email} with #{login}pass"
end

When /^I login asking to be remembered$/ do
  visit login_path
  When "I fill in login details with Fred and Fredpass"
  check 'remember_me'
  click_button
end

When /^I login asking not to be remembered$/ do
  visit login_path
  When "I fill in login details with Fred and Fredpass"
  uncheck 'remember_me'
  click_button
end

When /^I login as someone else and fail$/ do
  visit login_path
  When "I fill in login details with other_peep and fredpass"
  click_button
end

When /^I login as (.+) with (\S+)$/ do |user, password|
  visit login_path
  When "I fill in login details with #{user} and #{password}"
  find("#next_submit").find("input[type=image]").click
  page.should have_no_content("error prohibited this user session")
  #UserSession.create(@user)
end

When /^I fill in login details with (.+) and (.+)$/ do |user, password|
  fill_in("user_session_login", :with => user)
  fill_in("user_session_password", :with => password)
end

Given /^I am logged out$/ do
  post logout_path
end

When /^I logout$/ do
  post logout_path
end

Then /^my login status should be (.+)$/ do |status|
  controller.logged_in? ? status.should == 'in' : status.should == 'out'
end

Then /^I should be logged in$/ do
  controller.logged_in?.should be_true
end

Then /^I should be logged in as (.*)$/ do |login|
  Then "the user should be \"#{login}\""
  @user
end

Then /^I should not be logged in as (.*)$/ do |login|
  controller.current_user.should_not == User.find_by_login(login) if controller.logged_in?
end

Then /^I should not be logged in$/ do
  controller.logged_in?.should_not be_true
end

Then /^I should have my user id in my session store$/ do
  session[:user_id].should == @user.id
end

Then /^I should not have a user id in my session store$/ do
  session[:user_id].should be_nil
end

Then /^I should have an auth_token cookie$/ do
  cookies["auth_token"].should_not be_empty
end

Then /^I should not have an auth_token cookie$/ do
  cookies["auth_token"].should be_empty
end

When /^I'm logged in as (.*)$/ do |login|
  @user = User.find_by_login(login)
  UserSession.create(@user)
  Then "I should be logged in as #{login}"
end