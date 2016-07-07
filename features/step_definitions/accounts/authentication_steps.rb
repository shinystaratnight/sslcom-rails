#
# Helper Methods available to other steps
#

def create_user(login)
  @current_user = User.create!(
    :login => login,
    :password => 'generic',
    :password_confirmation => 'generic',
    :email => "#{login}@example.com"
  )
end

def login_user
  visit "/login"
  fill_in("login", :with => @current_user.login)
  fill_in("password", :with => 'generic')
  click_button("Login")
end

def logout_user
  session = UserSession.find
  session.destroy if session
end

def user_session
  @session ||= UserSession.find
end

#
# Cucumber Assertions
#

Given /\AI am the user "(.*)"\z/ do |login|
  create_user login
end

Given /\AI am logged in as "(.*)"\z/ do |login|
  create_user login
  login_user
end

#Given /\AI am not logged in\z/ do
#  logout_user
#end

When /\AI Log In\z/ do
  login_user
end

When /\AI logout\z/ do
  logout_user
end

Then /\Athere should be a session\z/ do
  user_session
  @session.should_not be nil
end

Then /\Athere should not be a session\z/ do
  user_session
  @session.should be nil
end

Then /\Athe user should be "([^"]*)"\z/ do |login| #"
  user_session
  @session.user.login.should be == login
end