When /\A(?:he|she|I) clicks? the first link in the email\z/ do
  link = links_in_email(current_email).first
  @browser.goto URI::parse(link)
end
