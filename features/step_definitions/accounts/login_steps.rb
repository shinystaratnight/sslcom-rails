When /\AI login as (\S+)\z/ do |login|
  When "I login as #{login} with #{login}pass"
end

When /\AI login as (\S+) from here\z/ do |login|
  When "I fill in login details with #{login} and #{login}pass"
  click_button
end

When /\AI login as (\S+) with my email address\z/ do |login|
  When "I login as #{User.find_by_login(login).email} with #{login}pass"
end

When /\AI login asking to be remembered\z/ do
  visit login_path
  When "I fill in login details with Fred and Fredpass"
  check 'remember_me'
  click_button
end

When /\AI login asking not to be remembered\z/ do
  visit login_path
  When "I fill in login details with Fred and Fredpass"
  uncheck 'remember_me'
  click_button
end

When /\AI login as someone else and fail\z/ do
  visit login_path
  When "I fill in login details with other_peep and fredpass"
  click_button
end

When /\AI login as (.+) with (\S+)\z/ do |user, password|
  visit login_path
  When "I fill in login details with #{user} and #{password}"
  find("#next_submit").find("input[type=image]").click
  page.should have_no_content("error prohibited this user session")
  #UserSession.create(@user.to_h)
end

When /\AI fill in login details with (.+) and (.+)\z/ do |user, password|
  fill_in("user_session_login", :with => user)
  fill_in("user_session_password", :with => password)
end

Given /\AI am logged out\z/ do
  post logout_path
end

When /\AI logout\z/ do
  post logout_path
end

Then /\Amy login status should be (.+)\z/ do |status|
  controller.logged_in? ? status.should == 'in' : status.should == 'out'
end

Then /\AI should be logged in\z/ do
  controller.logged_in?.should be_true
end

Then /\AI should be logged in as (.*)\z/ do |login|
  Then "the user should be \"#{login}\""
  @user
end

Then /\AI should not be logged in as (.*)\z/ do |login|
  controller.current_user.should_not == User.find_by_login(login) if controller.logged_in?
end

Then /\AI should not be logged in\z/ do
  controller.logged_in?.should_not be_true
end

Then /\AI should have my user id in my session store\z/ do
  session[:user_id].should == @user.id
end

Then /\AI should not have a user id in my session store\z/ do
  session[:user_id].should be_nil
end

Then /\AI should have an auth_token cookie\z/ do
  cookies["auth_token"].should_not be_empty
end

Then /\AI should not have an auth_token cookie\z/ do
  cookies["auth_token"].should be_empty
end

When /\AI'm logged in as (.*)\z/ do |login|
  @user = User.find_by_login(login)
  UserSession.create(@user.to_h)
  Then "I should be logged in as #{login}"
end