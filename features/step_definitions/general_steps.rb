Given /^an activated user with login ['"]([^'"]*)['"], password ['"]([^'"]*)['"], and email ['"]([^'"]*)['"] exists$/ do |login, password, email|
  u=User.create(:password=>password, :login=>login, :email=>email)
  u.create_ssl_account(:acct_number=>Time.now.to_i.to_s(16))
  u.active=true
  u.save
end

When /^(?:he|she|I) (uncheck|check) the checkbox with ['"]([^'"]*)['"](?:\s)?['"]([^'"]*)['"]$/ do |status,text, attribute|
  @browser.checkbox(attribute.intern, Regexp.new(text)).checked = (status=="check") ? true : false
end

When /^(?:he|she|I) clicks? the ['"]([^'"]*)['"] with ['"]([^'"]*)['"](?:\s)?['"]([^'"]*)['"]$/ do |element, text, attribute|
  get_element(element, attribute, text).click
end

When /^(?:he|she|I) clicks? the ['"]([^'"]*)['"] with ['"]([^'"]*)['"]$/ do |element, text|
  @browser.send(element.intern, :text, Regexp.new(text)).click
end

When /^(?:he|she|I) clicks? the ['"]([^'"]*)['"] button on the javascript popup ['"]([^'"]*)['"] launched by the ['"]([^'"]*)['"] with ['"]([^'"]*)['"] ['"]([^'"]*)['"]$/ do |popup_button, popup_text, element, text, attribute|
  @browser.startClicker(popup_button, 1, popup_text)
  @browser.send(element.intern, attribute.intern, Regexp.new(text)).click
end

When /^(?:he|she|I) clicks? the "([^"]*)" "([^"]*)"$/ do |text,element|
  @browser.send(element.intern, :text, Regexp.new(text)).click
end

When /^(?:he|she|I) clicks? the submit button$/ do
  @browser.button(:name, "commit").click
end

When /^(?:he|she|I) clicks? the (?:next|submit) (?:image\s)?button$/ do
  if is_capybara?
    unless first("[src*=next_bl]").blank?
      first("[src*=next_bl]").click
    else
      first("[src*=submit_button]").click
    end
  else
    if @browser.button(:src, /next_bl\.gif/).exists?
      @browser.button(:src, /next_bl\.gif/).click
    elsif @browser.button(:src, Regexp.new('submit_button')).exists?
      @browser.button(:src, Regexp.new('submit_button')).click
    end
  end
end

When /^(?:he|she|I) clicks? the next button and 'OK' on the popup confirmation$/ do
  @browser.startClicker('OK')
  @browser.button(:src, /next_bl\.gif/).click
end

When /^(?:he|she|I) enters? ['"]([^'"]*)['"] (?:in|into) the ['"]([^'"]*)['"] with attribute ['"]([^'"]*)['"] == ['"]([^'"]*)['"]$/ do |text, element, attribute, attribute_val|
  @browser.send(element.intern, attribute.intern, attribute_val.intern).value = text
end

When /^(?:he|she|I) enters? ['"]([^'"]*)['"] (?:in|into) the ['"]([^'"]*)['"]['"]([^'"]*)['"]$/ do |text, id, element|
  set_element(element, "id", id, text)
end

When /^(?:he|she|I) fills? the ['"]([^'"]*)['"] having attribute ['"]([^'"]*)['"] == ['"]([^'"]*)['"] with$/ do |element, attribute, attribute_val, pystring|
  set_element(element, attribute, attribute_val, pystring)
end

When /^(?:he|she|I) fills? the ['"]([^'"]*)['"](?:\s)?['"]([^'"]*)['"] with ['"]([^'"]*)['"]$/ do |id, element, text|
  @browser.send(element.intern, :id, id.intern).value = text
end

When /^(?:he|she|I) fills? the ['"]([^'"]*)['"](?:\s)?['"]([^'"]*)['"] indexed ['"](\d)['"] with ['"]([^'"]*)['"]$/ do |id, element, index, text|
  @browser.send(element.intern, :id=>id.intern, :index=>index.to_i).value = text
end

When /^(?:he|she|I) fills? all the ['"]([^'"]*)['"](?:\s)?['"]([^'"]*)['"]s with ['"]([^'"]*)['"]$/ do |id, element, text|
  @browser.elements_by_xpath("//#{element}[contains(@id,\'#{id}\')]").each do |e|
    e.value = text
  end
end

When /^(?:he|she|I) selects? ['"]([^'"]*)['"] as ['"]([^'"]*)['"]$/ do |value, id|
  if is_capybara?
    find("select[id*='#{id}']").set(value)
  else
    @browser.select_list(:id, Regexp.new(id)).value = value
  end
end

When /^(?:he|she|I) (?:is|am) prompted (?:to|for|with) ['"]([^'"]*)['"]$/ do |text|
  Then "I should see \'#{text}\'"
end

Then /^(?:he|she|I) should see a confirmation$/ do
  response.should have_flash
  response.flash.keys == [:notice]
end

Then /^(?:he|she|I) should see an error$/ do
  if is_capybara?
    page.should have_css('.flash_message.error')
  else
    response.should have_flash
    response.flash.keys == [:error]
  end
end

Then /^(?:he|she|I) should see a flash error message ['"]([^'"]*)['"]$/ do |msg|
  if is_capybara?
    page.should have_css('.flash_message.error')
    page.should have_content(msg)
  end
end

Then /^(?:he|she|I) should see an? error explanation$/ do
  if is_capybara?
    page.should have_css('.errorExplanation')
  else
    @browser.div(:class, "errorExplanation").should be
  end
end

Then /^(?:he|she|I) should see a notice explanation/ do
  if is_capybara?
    page.should have_css('.flash_message')
    page.should have_css('.notice')
  else
    @browser.div(:class, "flash_message").should be
    @browser.div(:class, "notice").should be
  end
end

Then /^(?:he|she|I) should see (?:the\s)?(notice|error) ['"]([^'"]*)['"]$/ do |type, text|
  steps %Q{
    Then I should see a #{type} explanation
      And I should see '#{text}'}
end

Then /^there should be an error field indicator$/ do
  if is_capybara?
    page.should have_css('.fieldWithErrors')
  else
    @browser.div(:class, "fieldWithErrors").should be
  end
end

Then /^there should be ['"](\d)['"] error field indicators?$/ do |count|
  @browser.elements_by_xpath("//div[contains(@class,\'fieldWithErrors\')]").
    count.should eql(count.to_i)
end

Then /^(?:he|she|I) should see a form$/ do
  @browser.html.should have_tag("form")
end

Then /^(?:he|she|I) should see ['"]([^'"]*)['"]$/ do |text|
  is_capybara? ? (page.should have_content(text)) : (@browser.text.downcase.should include(text.downcase))
end

Then /^(?:he|she|I) should not see ['"]([^'"]*)['"]$/ do |text|
  @browser.text.downcase.should_not include(text.downcase)
end

Then /^(?:he|she|I) should see ['"]([^'"]*)['"] in ['"]([^'"]*)['"]$/ do |text, attribute_val|
#  alternative function
#  doc = Hpricot(@browser.html)
#  (doc/"#{element}[@#{attribute}*=\'#{attribute_val}\']").first.inner_html.should include(text)
  sleep 1 if %w(cart_size cart_total).include? attribute_val
  @browser.elements_by_xpath("//*[@id=\'#{attribute_val}\']")[0].text.downcase.should include(text.downcase)
end

Then /^(?:he|she|I) should see a link pointing to ['"]([^'"]*)['"]$/ do |path|
  @browser.link(:href, "#{path}").text.downcase.should include(text.downcase)
end

Then /^(?:he|she|I) should see ['"]([^'"]*)['"] in the ['"]([^'"]*)['"] with attribute ['"]([^'"]*)['"] == ['"]([^'"]*)['"]$/ do |text, element, attribute, attribute_val|
#  alternative function
#  doc = Hpricot(@browser.html)
#  (doc/"#{element}[@#{attribute}*=\'#{attribute_val}\']").first.inner_html.should include(text)
  element=transform_element(element)
  tag=@browser.elements_by_xpath("//#{element}[contains(@#{attribute},\'#{attribute_val}\')]").find do |tag|
    tm = tag.method(element=='input' ? :value : :text)
    tm.call.downcase.include?(text.downcase)
  end
  tm = tag.method(element=='input' ? :value : :text)
  tm.call.downcase.should include(text.downcase)
end

Then /^(?:he|she|I) should see ['"]([^'"]*)['"] in the ['"]([^'"]*)['"](?:\s)?['"]([^'"]*)['"]$/ do |text, id, element|
  element=transform_element(element)
  if is_capybara?
   find(:xpath, "//#{element}[contains(@id,\'#{id}\')]").should have_content(text)
  else
    tag=@browser.elements_by_xpath("//#{element}[contains(@id,\'#{id}\')]").find do |tag|
      tm = tag.method(element=='input' ? :value : :text)
      tm.call.downcase.include?(text.downcase)
    end
    tm = tag.method(element=='input' ? :value : :text)
    tm.call.downcase.should include(text.downcase)
  end
end

Then /^(?:he|she|I) should see the checkbox with ['"]([^'"]*)['"](?:\s)?['"]([^'"]*)['"] (unchecked|checked)$/ do |attribute_val,attribute,status|
  be_or_not = (status=="checked") ? be_true : be_false
  @browser.checkbox(attribute.intern, Regexp.new(attribute_val)).checked.should be_or_not
end

Transform /^user (.+?)$/ do |username|
  @current_user || 
    without_access_control do
      @current_user = User.find_by_login username
      @current_user
    end
end

Given /^['"](user .+?)['"]'s roles? ['"]([^'"]*)['"] ['"]([^'"]*)['"]$/ do |user, equality, role|
  case equality
  when /is/
    without_access_control do
        user.roles.clear
        user.roles << Role.find_by_name(role)
      end
  end
end

Then /^(\S+) should be denied$/ do |user|
  page.should have_content("You currently do not have permission to access that page.")
end

def transform_element(element)
  case element
  when "link"
    "a"
  when "text_field"
    "input"
  else
    element
  end
end

