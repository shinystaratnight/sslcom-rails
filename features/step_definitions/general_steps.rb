Given /\Aan activated user with login ['"]([^'"]*)['"], password ['"]([^'"]*)['"], and email ['"]([^'"]*)['"] exists\z/ do |login, password, email|
  u=User.create(:password=>password, :login=>login, :email=>email)
  u.create_ssl_account(:acct_number=>Time.now.to_i.to_s(16))
  u.active=true
  u.save
end

When /\A(?:he|she|I) (uncheck|check) the checkbox with ['"]([^'"]*)['"](?:\s)?['"]([^'"]*)['"]\z/ do |status,text, attribute|
  @browser.checkbox(attribute.intern, Regexp.new(text)).checked = (status=="check") ? true : false
end

When /\A(?:he|she|I) clicks? the ['"]([^'"]*)['"] with ['"]([^'"]*)['"](?:\s)?['"]([^'"]*)['"]\z/ do |element, text, attribute|
  get_element(element, attribute, text).click
end

When /\A(?:he|she|I) clicks? the ['"]([^'"]*)['"] with ['"]([^'"]*)['"]\z/ do |element, text|
  @browser.send(element.intern, :text, Regexp.new(text)).click
end

When /\A(?:he|she|I) clicks? the ['"]([^'"]*)['"] button on the javascript popup ['"]([^'"]*)['"] launched by the ['"]([^'"]*)['"] with ['"]([^'"]*)['"] ['"]([^'"]*)['"]\z/ do |popup_button, popup_text, element, text, attribute|
  @browser.startClicker(popup_button, 1, popup_text)
  @browser.send(element.intern, attribute.intern, Regexp.new(text)).click
end

When /\A(?:he|she|I) clicks? the "([^"]*)" "([^"]*)"\z/ do |text,element|
  @browser.send(element.intern, :text, Regexp.new(text)).click
end

When /\A(?:he|she|I) clicks? the submit button\z/ do
  @browser.button(:name, "commit").click
end

When /\A(?:he|she|I) clicks? the (?:next|submit) (?:image\s)?button\z/ do
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

When /\A(?:he|she|I) clicks? the next button and 'OK' on the popup confirmation\z/ do
  @browser.startClicker('OK')
  @browser.button(:src, /next_bl\.gif/).click
end

When /\A(?:he|she|I) enters? ['"]([^'"]*)['"] (?:in|into) the ['"]([^'"]*)['"] with attribute ['"]([^'"]*)['"] == ['"]([^'"]*)['"]\z/ do |text, element, attribute, attribute_val|
  @browser.send(element.intern, attribute.intern, attribute_val.intern).value = text
end

When /\A(?:he|she|I) enters? ['"]([^'"]*)['"] (?:in|into) the ['"]([^'"]*)['"]['"]([^'"]*)['"]\z/ do |text, id, element|
  set_element(element, "id", id, text)
end

When /\A(?:he|she|I) fills? the ['"]([^'"]*)['"] having attribute ['"]([^'"]*)['"] == ['"]([^'"]*)['"] with\z/ do |element, attribute, attribute_val, pystring|
  set_element(element, attribute, attribute_val, pystring)
end

When /\A(?:he|she|I) fills? the ['"]([^'"]*)['"](?:\s)?['"]([^'"]*)['"] with ['"]([^'"]*)['"]\z/ do |id, element, text|
  @browser.send(element.intern, :id, id.intern).value = text
end

When /\A(?:he|she|I) fills? the ['"]([^'"]*)['"](?:\s)?['"]([^'"]*)['"] indexed ['"](\d)['"] with ['"]([^'"]*)['"]\z/ do |id, element, index, text|
  @browser.send(element.intern, :id=>id.intern, :index=>index.to_i).value = text
end

When /\A(?:he|she|I) fills? all the ['"]([^'"]*)['"](?:\s)?['"]([^'"]*)['"]s with ['"]([^'"]*)['"]\z/ do |id, element, text|
  @browser.elements_by_xpath("//#{element}[contains(@id,\'#{id}\')]").each do |e|
    e.value = text
  end
end

When /\A(?:he|she|I) selects? ['"]([^'"]*)['"] as ['"]([^'"]*)['"]\z/ do |value, id|
  if is_capybara?
    select(value, from: id)
  else
    @browser.select_list(:id, Regexp.new(id)).value = value
  end
end

When /\A(?:he|she|I) (?:is|am) prompted (?:to|for|with) ['"]([^'"]*)['"]\z/ do |text|
  Then "I should see \'#{text}\'"
end

Then /\A(?:he|she|I) should see a confirmation\z/ do
  response.should have_flash
  response.flash.keys == [:notice]
end

Then /\A(?:he|she|I) should see an error\z/ do
  if is_capybara?
    page.should have_css('.flash_message.error')
  else
    response.should have_flash
    response.flash.keys == [:error]
  end
end

Then /\A(?:he|she|I) should not see any? errors?\z/ do
  page.should_not have_css('.flash_message.error')
  page.should_not have_css('.errorExplanation')
end

Then /\A(?:he|she|I) should see a flash error message ['"]([^'"]*)['"]\z/ do |msg|
  if is_capybara?
    page.should have_css('.flash_message.error')
    page.should have_content(msg)
  end
end

Then /\A(?:he|she|I) should see an? error explanation\z/ do
  if is_capybara?
    page.should have_css('.errorExplanation')
  else
    @browser.div(:class, "errorExplanation").should be
  end
end

Then /\A(?:he|she|I) should see a notice explanation/ do
  if is_capybara?
    page.should have_css('.flash_message')
    page.should have_css('.notice')
  else
    @browser.div(:class, "flash_message").should be
    @browser.div(:class, "notice").should be
  end
end

Then /\A(?:he|she|I) should see (?:the\s)?(notice|error) ['"]([^'"]*)['"]\z/ do |type, text|
  steps %Q{
    Then I should see a #{type} explanation
      And I should see '#{text}'}
end

Then /\Athere should be an error field indicator\z/ do
  if is_capybara?
    page.should have_css('.fieldWithErrors')
  else
    @browser.div(:class, "fieldWithErrors").should be
  end
end

Then /\Athere should be ['"](\d)['"] error field indicators?\z/ do |count|
  @browser.elements_by_xpath("//div[contains(@class,\'fieldWithErrors\')]").
    count.should eql(count.to_i)
end

Then /\A(?:he|she|I) should see a form\z/ do
  @browser.html.should have_tag("form")
end

Then /\A(?:he|she|I) should see ['"]([^'"]*)['"]\z/ do |text|
  is_capybara? ? (page.should have_content(text)) : (@browser.text.downcase.should include(text.downcase))
end

Then /\A(?:he|she|I) should not see ['"]([^'"]*)['"]\z/ do |text|
  @browser.text.downcase.should_not include(text.downcase)
end

Then /\A(?:he|she|I) should see ['"]([^'"]*)['"] in ['"]([^'"]*)['"]\z/ do |text, attribute_val|
#  alternative function
#  doc = Hpricot(@browser.html)
#  (doc/"#{element}[@#{attribute}*=\'#{attribute_val}\']").first.inner_html.should include(text)
  sleep 1 if %w(cart_size cart_total).include? attribute_val
  @browser.elements_by_xpath("//*[@id=\'#{attribute_val}\']")[0].text.downcase.should include(text.downcase)
end

Then /\A(?:he|she|I) should see a link pointing to ['"]([^'"]*)['"]\z/ do |path|
  @browser.link(:href, "#{path}").text.downcase.should include(text.downcase)
end

Then /\A(?:he|she|I) should see ['"]([^'"]*)['"] in the ['"]([^'"]*)['"] with attribute ['"]([^'"]*)['"] == ['"]([^'"]*)['"]\z/ do |text, element, attribute, attribute_val|
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

Then /\A(?:he|she|I) should see ['"]([^'"]*)['"] in the ['"]([^'"]*)['"](?:\s)?['"]([^'"]*)['"]\z/ do |text, id, element|
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

Then /\A(?:he|she|I) should see the checkbox with ['"]([^'"]*)['"](?:\s)?['"]([^'"]*)['"] (unchecked|checked)\z/ do |attribute_val,attribute,status|
  be_or_not = (status=="checked") ? be_true : be_false
  @browser.checkbox(attribute.intern, Regexp.new(attribute_val)).checked.should be_or_not
end

Transform /\Auser (.+?)\z/ do |username|
  @current_user || 
    without_access_control do
      @current_user = User.find_by_login username
      @current_user
    end
end

Given /\A['"](user .+?)['"]'s roles? ['"]([^'"]*)['"] ['"]([^'"]*)['"]\z/ do |user, equality, role|
  case equality
  when /is/
    without_access_control do
        user.roles.clear
        user.roles << Role.find_by_name(role)
      end
  end
end

Then /\A(\S+) should be denied\z/ do |user|
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

