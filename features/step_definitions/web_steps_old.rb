# Commonly used webrat steps
# http://github.com/brynary/webrat

When /\AI press "(.*)"\z/ do |button|
  click_button(button)
end

When /\AI follow "(.*)"\z/ do |link|
  click_link(link)
end

When /\AI fill in "(.*)" with "(.*)"\z/ do |field, value|
  fill_in(field, :with => value)
end

When /\AI select "(.*)" from "(.*)"\z/ do |value, field|
  select(value, :from => field)
end

# Use this step in conjunction with Rail's datetime_select helper. For example:
# When I select "December 25, 2008 10:00" as the date and time
When /\AI select "(.*)" as the date and time\z/ do |time|
  select_datetime(time)
end

# Use this step when using multiple datetime_select helpers on a page or
# you want to specify which datetime to select. Given the following view:
#   <%= f.label :preferred %><br />
#   <%= f.datetime_select :preferred %>
#   <%= f.label :alternative %><br />
#   <%= f.datetime_select :alternative %>
# The following steps would fill out the form:
# When I select "November 23, 2004 11:20" as the "Preferred" data and time
# And I select "November 25, 2004 10:30" as the "Alternative" data and time
When /\AI select "(.*)" as the "(.*)" date and time\z/ do |datetime, datetime_label|
  select_datetime(datetime, :from => datetime_label)
end

# Use this step in conjuction with Rail's time_select helper. For example:
# When I select "2:20PM" as the time
# Note: Rail's default time helper provides 24-hour time-- not 12 hour time. Webrat
# will convert the 2:20PM to 14:20 and then select it.
When /\AI select "(.*)" as the time\z/ do |time|
  select_time(time)
end

# Use this step when using multiple time_select helpers on a page or you want to
# specify the name of the time on the form.  For example:
# When I select "7:30AM" as the "Gym" time
When /\AI select "(.*)" as the "(.*)" time\z/ do |time, time_label|
  select_time(time, :from => time_label)
end

# Use this step in conjuction with Rail's date_select helper.  For example:
# When I select "February 20, 1981" as the date
When /\AI select "(.*)" as the date\z/ do |date|
  select_date(date)
end

# Use this step when using multiple date_select helpers on one page or
# you want to specify the name of the date on the form. For example:
# When I select "April 26, 1982" as the "Date of Birth" date
When /\AI select "(.*)" as the "(.*)" date\z/ do |date, date_label|
  select_date(date, :from => date_label)
end

When /\AI check "(.*)"\z/ do |field|
  check(field)
end

When /\AI uncheck "(.*)"\z/ do |field|
  uncheck(field)
end

When /\AI choose "(.*)"\z/ do |field|
  choose(field)
end

When /\A(?:he|she|I) attach the file at "(.*)" to "(.*)" \z/ do |path, field|
  attach_file(field, path)
end

#Then /\A(?:he|she|I) should see "(.*)"\z/ do |text|
#  response.body.should =~ /#{text}/m
#end

#Then /\A(?:he|she|I) should not see "(.*)"\z/ do |text|
#  response.body.should_not =~ /#{text}/m
#end

Then /\Athe "(.*)" checkbox should be checked\z/ do |label|
  field_labeled(label).should be_checked
end
