When /^(?:he|she|I) clicks? the first link in the email$/ do
  link = links_in_email(current_email).first
  @browser.goto URI::parse(link)
end
