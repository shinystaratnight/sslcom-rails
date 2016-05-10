Given /\AI am a registered user\z/ do
  Given "a registered user Fred exists"
end

Given /\AI am an activated user\z/ do
  Given "an activated user Fred exists"
end

When /\AI activate myself\z/ do
  get "/activate/#{@user.activation_code }"

  # Have to do this otherwise variable won't show that its state has changed
  @user.reload
end


When /\AI activate myself without an activation code\z/ do
  get '/activate/'
  # Have to do this otherwise variable won't show that its state has changed
  @user.reload
end

When /\AI activate myself with a bogus activation code\z/ do
  bogus_code = "jhadasj637687ea"
  get "/activate/#{@bogus_code }"
  # Have to do this otherwise variable won't show that its state has changed
  @user.reload
end

Then /\AI should be activated\z/ do
  @user.state.should == 'active'
end

Then /\AI should not be activated\z/ do
  @user.state.should_not == 'active'
end