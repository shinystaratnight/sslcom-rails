# Commonly used email steps
#
# To add your own steps make a custom_email_steps.rb
# The provided methods are:
#
# last_email_address
# reset_mailer
# open_last_email
# visit_in_email
# unread_emails_for
# mailbox_for
# current_email
# open_email
# read_emails_for
# find_email
#
# General form for email scenarios are:
#   - clear the email queue (done automatically by email_spec)
#   - execute steps that sends an email
#   - check the user received an/no/[0-9] emails
#   - open the email
#   - inspect the email contents
#   - interact with the email (e.g. click links)
#
# The Cucumber steps below are setup in this order.

module EmailHelpers
  def current_email_address
    # Replace with your a way to find your current email. e.g @current_user.email
    # last_email_address will return the last email address used by email spec to find an email.
    # Note that last_email_address will be reset after each Scenario.
    last_email_address || "example@example.com"
  end
end

World(EmailHelpers)

#
# Reset the e-mail queue within a scenario.
# This is done automatically before each scenario.
#

Given /\A(?:a clear email queue|no emails have been sent)\z/ do
  reset_mailer
end

#
# Check how many emails have been sent/received
#

Then /\A(?:I|they|"([^"]*?)") should receive (an|no|\d+) emails?\z/ do |address, amount|
  unread_emails_for(address).size.should == parse_email_count(amount)
end

Then /\A(?:I|they|"([^"]*?)") should have (an|no|\d+) emails?\z/ do |address, amount|
  mailbox_for(address).size.should == parse_email_count(amount)
end

Then /\A(?:I|they|"([^"]*?)") should receive (an|no|\d+) emails? with subject "([^"]*?)"\z/ do |address, amount, subject|
  unread_emails_for(address).select { |m| m.subject =~ Regexp.new(subject) }.size.should == parse_email_count(amount)
end

Then /\A(?:I|they|"([^"]*?)") should receive an email with the following body:\z/ do |address, expected_body|
  open_email(address, :with_text => expected_body)
end

#
# Accessing emails
#

# Opens the most recently received email
When /\A(?:I|they|"([^"]*?)") opens? the email\z/ do |address|
  open_email(address)
end

When /\A(?:I|they|"([^"]*?)") opens? the email with subject "([^"]*?)"\z/ do |address, subject|
  open_email(address, :with_subject => subject)
end

When /\A(?:I|they|"([^"]*?)") opens? the email with text "([^"]*?)"\z/ do |address, text|
  open_email(address, :with_text => text)
end

#
# Inspect the Email Contents
#

Then /\A(?:I|they) should see "([^"]*?)" in the email subject\z/ do |text|
  current_email.should have_subject(text)
end

Then /\A(?:I|they) should see \/([^"]*?)\/ in the email subject\z/ do |text|
  current_email.should have_subject(Regexp.new(text))
end

Then /\A(?:I|they) should see "([^"]*?)" in the email body\z/ do |text|
  current_email.default_part_body.to_s.should include(text)
end

Then /\A(?:I|they) should see \/([^"]*?)\/ in the email body\z/ do |text|
  current_email.default_part_body.to_s.should =~ Regexp.new(text)
end

Then /\A(?:I|they) should see the email delivered from "([^"]*?)"\z/ do |text|
  current_email.should be_delivered_from(text)
end

Then /\A(?:I|they) should see "([^\"]*)" in the email "([^"]*?)" header\z/ do |text, name|
  current_email.should have_header(name, text)
end

Then /\A(?:I|they) should see \/([^\"]*)\/ in the email "([^"]*?)" header\z/ do |text, name|
  current_email.should have_header(name, Regexp.new(text))
end

Then /\AI should see it is a multi\-part email\z/ do
    current_email.should be_multipart
end

Then /\A(?:I|they) should see "([^"]*?)" in the email html part body\z/ do |text|
    current_email.html_part.body.to_s.should include(text)
end

Then /\A(?:I|they) should see "([^"]*?)" in the email text part body\z/ do |text|
    current_email.text_part.body.to_s.should include(text)
end

#
# Inspect the Email Attachments
#

Then /\A(?:I|they) should see (an|no|\d+) attachments? with the email\z/ do |amount|
  current_email_attachments.size.should == parse_email_count(amount)
end

Then /\Athere should be (an|no|\d+) attachments? named "([^"]*?)"\z/ do |amount, filename|
  current_email_attachments.select { |a| a.filename == filename }.size.should == parse_email_count(amount)
end

Then /\Aattachment (\d+) should be named "([^"]*?)"\z/ do |index, filename|
  current_email_attachments[(index.to_i - 1)].filename.should == filename
end

Then /\Athere should be (an|no|\d+) attachments? of type "([^"]*?)"\z/ do |amount, content_type|
  current_email_attachments.select { |a| a.content_type.include?(content_type) }.size.should == parse_email_count(amount)
end

Then /\Aattachment (\d+) should be of type "([^"]*?)"\z/ do |index, content_type|
  current_email_attachments[(index.to_i - 1)].content_type.should include(content_type)
end

Then /\Aall attachments should not be blank\z/ do
  current_email_attachments.each do |attachment|
    attachment.read.size.should_not == 0
  end
end

Then /\Ashow me a list of email attachments\z/ do
  EmailSpec::EmailViewer::save_and_open_email_attachments_list(current_email)
end

#
# Interact with Email Contents
#

When /\A(?:I|they) follow "([^"]*?)" in the email\z/ do |link|
  visit_in_email(link)
end

When /\A(?:I|they) click the first link in the email\z/ do
  click_first_link_in_email
end

#
# Debugging
# These only work with Rails and OSx ATM since EmailViewer uses Rails.root and OSx's 'open' command.
# Patches accepted. ;)
#

Then /\Asave and open current email\z/ do
  EmailSpec::EmailViewer::save_and_open_email(current_email)
end

Then /\Asave and open all text emails\z/ do
  EmailSpec::EmailViewer::save_and_open_all_text_emails
end

Then /\Asave and open all html emails\z/ do
  EmailSpec::EmailViewer::save_and_open_all_html_emails
end

Then /\Asave and open all raw emails\z/ do
  EmailSpec::EmailViewer::save_and_open_all_raw_emails
end
