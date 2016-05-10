When /\AI fill in (.*) signup details\z/ do |user|
  fill_in(:login, :with => user)
  fill_in(:email, :with => user + '@example.com')
  fill_in(:password, :with => user + 'pass')
  fill_in('user[password_confirmation]', :with => user + 'pass')
end

When /\AI signup as (\w*)\z/ do |user|
  When "I visit signup"
  When "I fill in #{user} signup details"
  click_button
end

When /\AI signup as (.*) with wrong confirmation\z/ do |user|
  When "I visit signup"
  When "I fill in #{user} signup details"
  fill_in('user[password_confirmation]', :with => 'poopypoop')
  click_button
end

When /\AI signup as (.*) without (.*)\z/ do |user, field|
  When "I visit signup"
  When "I fill in #{user} signup details"
  field == 'password_confirmation' ? fill_in('user[password_confirmation]', :with => '') : fill_in(field, :with => '')
  click_button
end

Then /\Athere should be an account for Fred\z/ do
  User.count.should == 1
end

# by default create named user with attributes done by convention
When /\AI create an? (\S+) with login (\w*)\z/ do |type, login|
  without_access_control do
    @user = FactoryGirl.create(type.to_sym, :login => login,
      password: login + "pass",
      password_confirmation: login + "pass",
      email: login + "@example.com",
      password_salt: salt = Authlogic::Random.hex_token,
      crypted_password: Authlogic::CryptoProviders::Sha512.encrypt(login + "pass" + salt),
      persistence_token: Authlogic::Random.hex_token,
      single_access_token: Authlogic::Random.friendly_token,
      perishable_token: Authlogic::Random.friendly_token)
  end
end

When /\AI register a user with login (\w*)\z/ do |login|
  @user = User.find_by_login(login)
  @user.active=true
  @user.save
  @user.should be_active
  @user
end

When /\AI activate a user with login (\w*)\z/ do |login|
  @user = User.find_by_login(login)
  @user.active=true
  @user.save
  @user.should be_active
  @user
end

Given /\Aa registered (\S+) (\w*) exists\z/ do |type, user|
  type = "customer" if type=="user"
  When "I create a #{type} with login #{user}"
   And "I register a user with login #{user}"

end

Given /\Aan activated (\S+) (\w*) exists\z/ do |type, user|
  type = "customer" if type=="user"
  When "I create a #{type} with login #{user}"
   And "I register a user with login #{user}"
   And "I activate a user with login #{user}"
end

Given /\Aan admin user (\w*) exists\z/ do |user|
  When "I create a user with login #{user}"
   And "I register a user with login #{user}"
   And "I activate a user with login #{user}"
   @user.admin = true
   @user.save!
   @user.should be_admin
end

Then /\AFred's details should be unchanged\z/ do
  @user.should == User.find_by_login('Fred')
end

Given /\Aa duplicate login (\S+) exists\z/ do |login|
  FactoryGirl.create(:duplicate_v2_user, :login => login)
  FactoryGirl.create(:duplicate_v2_user, :login => login)
end

Given /\Aa duplicate email (\S+) exists/ do |email|
  FactoryGirl.create(:duplicate_v2_user, :email => email)
  FactoryGirl.create(:duplicate_v2_user, :email => email)
end