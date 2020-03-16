# frozen_string_literal: true

Given /\A(?:he|she|I) buys? a ['"]([^'"]*)['"] (?:duration\s)?['"]([^'"]*)['"] (?:year\s)?certificate using csr ['"]([^'"]*)['"]\z/ do |type, duration, csr|
  csr = eval("@#{csr}").gsub(/\r\n/, "\n")
  When "he goes to the '#{type}' certificate buy page"
  And "he fills the 'text_field' having attribute 'id' == 'signing_request' with", csr
  And "he selects 'OTHER' as 'certificate_order_certificate_contents_attributes_0_server_software_id'"
  And "he clicks the 'radio' with '#{duration}' 'value'"
  And 'he clicks the next image button'
end

Given /\A(?:his|her|my)(?: shopping)? cart is empty\z/ do
  if is_capybara?
    visit(show_cart_orders_path)
    find('#clear_cart').click if page.has_selector?('#clear_cart')
  else
    @browser.goto APP_URL + show_cart_orders_path
    @browser.span(:id, 'clear_cart').click if
      @browser.span(:id, 'clear_cart').exists?
  end
end

Given /\Athe following non-wildcard signed certificate exists\z/ do |pystring|
  @signed_certificate = pystring
end

Given /\Athere is an open certificate order with ref number ['"]([^'"]*)['"]\z/ do |ref|
  without_access_control do
    @current_order = CertificateOrder.find_by_ref(ref)
    @current_order.should_not be_nil
  end
end

Given /\Athere is a processed certificate order with ref number ['"]([^'"]*)['"]\z/ do |ref|
  without_access_control do
    co = CertificateOrder.find_by_ref(ref)
    co.certificate_content.csr.signed_certificate = SignedCertificate.new(body: @lobby_sb_betsoftgaming_com_signed_cert)
    co.certificate_content.csr.signed_certificate.save
  end
end

Given /\A['"](user .+?)['"]'s expiration trigger is set to ['"]([^'"]*)['"] ['"]([^'"]*)['"]\z/ do |user, days, order|
  user.ssl_account.preferred_reminder_notice_triggers = days.to_i, order.to_i
  user.ssl_account.save
end

Given /\Acertificate order ['"]([^'"]*)['"] does not have a signed certificate\z/ do |cert|
  without_access_control do
    co = CertificateOrder.find_by_ref(cert)
    co.certificate_content.csr.signed_certificate.destroy unless
      co.certificate_content.csr.signed_certificate.blank?
    co.certificate_content.csr.signed_certificate.should be_blank
  end
end

Given /\A(?:his|her|my) reseller account has ['"]([^'"]*)['"] available\z/ do |amount|
  without_access_control do
    @current_user.ssl_account.funded_account.update_attribute(:cents, amount.gsub(/[^\d\.]/, '').to_i * 100)
  end
end

When /\A(?:he|she|I) adds? a ['"]([^'"]*)['"] year ['"]([^'"]*)['"] ssl certificate to the cart\z/ do |duration, type|
  When "he goes to the '#{type}' certificate buy page"
  And "he clicks the 'radio' with 'certificate_order_has_csr_false' 'id'"
  And "he clicks the 'radio' with '#{duration}' 'value'"
  And 'he clicks the next image button'
end

When /\A(?:he|she|I) adds? a ['"]([^'"]*)['"] year ['"]([^'"]*)['"] ssl certificate with domains ['"]([^'"]*)['"] to the cart\z/ do |duration, type, domains|
  When "he goes to the '#{type}' certificate buy page"
  And "he clicks the 'radio' with 'certificate_order_has_csr_false' 'id'"
  And "he fills the 'text_field' having attribute 'name' == 'additional_domains' with", domains
  And "he clicks the 'radio' with '#{duration}' 'value'"
  And 'he clicks the next image button'
end

When /\A(?:he|she|I) check(?:s)?out\z/ do
  goto new_order_path
end

When /\A(?:he|she|I) go(?:es)? to the ['"]([^'"]*)['"] certificate buy page\z/ do |type|
  ->(x){ is_capybara? ? visit(x) : @browser.goto(APP_URL + x) }.call(buy_certificate_path(type))
end

When /\A(?:he|she|I) applies the order to the reseller account\z/ do
  without_access_control do
    lambda{
      @browser.button(:src, /next_bl\.gif/).click
    }.should change { User.find_by_login(@current_user.login).ssl_account.funded_account.cents }
      .by(-@current_user.ssl_account.cached_certificate_orders.last.amount)
  end
end

When /\A(?:he|she|I) clicks the link to the current certificate order in progress\z/ do
  co = @current_order || @current_user.ssl_account.cached_certificate_orders.last
  @browser.link(:href, Regexp.new(certificate_order_path(co.ref))).click
end

When /\A(?:he|she|I) go(?:es)? to the certificate order page for ['"]([^'"]*)['"]\z/ do |ref|
  goto certificate_order_path(ref)
end

When /\A(?:he|she|I) go(?:es)? to the certificate order page\z/ do
  visit certificate_order_path(@certificate_order.ref)
end

When /\Acertificate order ['"]([^'"]*)['"] is expiring in ['"]([^'"]*)['"]\z/ do |ref, days|
  without_access_control do
    co = CertificateOrder.find_by_ref(ref)
    co.certificate_content.csr.signed_certificate.update_attribute :expiration_date, days.to_i.days.from_now
  end
end

When /\A(?:he|she|I) fills in the applicant information using\z/ do |table|
  fields = defined? table.hashes || [table]
  fields.each do |field|
    @browser.text_field(:id, Regexp.new('department')).value = field['department']
    @browser.text_field(:id, Regexp.new('po_box')).value = field['po_box']
    @browser.text_field(:id, Regexp.new('address1')).value = field['address1']
    @browser.text_field(:id, Regexp.new('postal_code')).value = field['postal_code']
  end
end

When /\A(?:he|she|I) submits? ['"]([^'"]*)['"] as the signed certificate\z/ do |cert|
  fill_text 'signed_certificate_body', cert
  if is_capybara?
    click_on 'Submit certificate'
    page.driver.browser.switch_to.alert.text.should have_content('invalid')
    page.driver.browser.switch_to.alert.dismiss
  else
    @browser.startClicker('OK')
    @browser.button(:class, 'submit_signed_certificate').click_no_wait
    # @browser.get_popup_text.should include('invalid')
    # p.should include('valid')
  end
end

When /\A(?:he|she|I) (re)?submits? the variable ['"]([^'"]*)['"] as the signed certificate\z/ do |resubmit, cert|
  fill_text 'signed_certificate_body', eval(cert.to_s).gsub(/\r\n/, "\n")
  if is_capybara?
    click_on 'Submit certificate'
    handle_js_confirm(true){ page.driver.browser.switch_to.alert.accept }
  else
    @browser.startClicker('OK') if resubmit
    @browser.button(:class, 'submit_signed_certificate').click
    # give a chance for the fields to be updated
    sleep 5
  end
end

When /\A(?:he|she|I) clicks? the action link for the currently displayed order\z/ do
  co = @current_order || @current_user.ssl_account.cached_certificate_orders.last
  @browser.link(:href, Regexp.new(edit_certificate_order_path(co.ref))).click
end

When /\A(?:he|she|I) enters? (?:his|her|my) new user information\z/ do |table|
  profiles = defined? table.hashes || [table]
  profiles.each do |profile|
    { 'user_login' => profile['login'], 'user_email' => profile['email'],
      'user_password' => profile['password'], 'user_password_confirmation' => profile['confirm'] }.each do |k, v|
      fill_text(k, v)
    end
  end
end

When /\A(?:he|she|I) enters? (?:his|her|my|the) registrant information\z/ do |table|
  profiles = defined? table.hashes || [table]
  profiles.each do |profile|
    { 'certificate_order_certificate_contents_attributes_0_registrant_attributes_address1' => profile['address1'],
      'certificate_order_certificate_contents_attributes_0_registrant_attributes_postal_code' => profile['postal_code'] }
      .each do |k, v|
      fill_text(k, v)
    end
  end
end

When /\A(?:he|she|I) enters? (?:his|her|my) login information\z/ do |table|
  profiles = defined? table.hashes || [table]
  profiles.each do |profile|
    { 'user_session_login' => profile['login'],
      'user_session_password' => profile['password'] }.each do |k, v|
      fill_text(k, v)
    end
  end
end

When /\A(?:he|she|I) ajax logs? in using/ do |table|
  profiles = defined? table.hashes || [table]
  profiles.each do |profile|
    { 'user_session_login' => profile['login'],
      'user_session_password' => profile['password'] }.each do |k, v|
      fill_text(k, v)
    end
  end
  And 'I click the submit image button'
  # Then "I should see a popup containing 'Ooops'"
  page.driver.browser.switch_to.alert.accept
end

When /\A(?:he|she|I) add (?:an\s)?ssl certificates? to the cart\z/ do |table|
  @order_total = 0
  profiles = defined? table.hashes || [table]
  profiles.each do |profile|
    if profile['domains'].blank?
      When "I add a '#{profile['years']}' year '#{profile['product']}' ssl certificate to the cart"
    else
      When "I add a '#{profile['years']}' year '#{profile['product']}' ssl certificate with domains '#{profile['domains']}' to the cart"
    end
    @order_total += profile['price'].to_f
  end
end

Then /\Athe order amount displayed should be the same as the cart amount\z/ do
  Then "I should see '#{@order_total}'"
  #    And "I should see '#{@order_total}' in the 'input' with attribute 'id' == 'order_amount'"
end

Then /\A(?:he|she|I) should see a popup containing ['"]([^'"]*)['"]\z/ do |text|
  if is_capybara?
    page.driver.browser.switch_to.alert.text.should have_content(text)
  else
    @browser.get_popup_text.should include(text)
  end
end

Then /\Athere should ['"]([^'"]*)['"] be an (expiring|expired) indicator\z/ do |be_or_not, status|
  expected_class = status == 'expiring' ? 'expiration_warning' : 'attention'
  @browser.elements_by_xpath("//td[@class='#{expected_class}']/span[@class='expires_on']").should_not be_empty unless be_or_not == 'not'
end

Then /\A(?:he|she|I) should see line items for this order\z/ do
  @browser.text.should include(order_line_items(@current_user.ssl_account.cached_certificate_orders.last))
end

Then /\A(?:her|his|my) cart should be empty\z/ do
  @browser.goto APP_URL + show_cart_orders_path
  Then "I should see '0.00'"
end

Then /\Athe certificate content fields should (?:remain the same as|be updated with) ['"]([^'"]*)['"] fields\z/ do |cert|
  sc = SignedCertificate.new(body: eval(cert.to_s))
  sc_fields = [sc.common_name,
               sc.organization,
               sc.country,
               sc.expiration_date.strftime('%b %d, %Y'),
               'submitted on ' + Date.today.strftime('%b %d, %Y')]
  sc_fields << sc.organization_unit unless sc.organization_unit.blank?
  sc_fields << sc.state unless sc.state.blank?
  sc_fields << sc.locality unless sc.locality.blank?
  sc_fields.flatten.each do |f|
    should_have(f)
  end
end

Then /\A(?:he|she|I) ['"]([^'"]*)['"] authorized to ['"]([^'"]*)['"] the ['"]([^'"]*)['"] ['"]([^'"]*)['"] object\z/ do |permission, action, id, element|
  case action
  when /have on the page/
    should_or_not = permission == 'is' ? :should_not : :should
    @browser.send(element.to_sym, 'id', id).send(should_or_not, raise_error)
  end
end

Then /\A(?:he|she|I) should be at step ['"]([^'"]*)['"] of ['"]([^'"]*)['"]\z/ do |index, count|
  lambda{ |e|
    (is_capybara? ? find(:xpath, e) :
      @browser.elements_by_xpath(e)).first.text.should include(index + ' ')
  } .call("//li[@id='selected']")
  lambda{ |e|
    (is_capybara? ? find(:xpath, e) :
      @browser.elements_by_xpath(e)).count.should eql(count.to_i)
  } .call("//div[@id='form_progress_indicator']/ul/li")
end

Then /\A(?:he|she|I) should see (\d+) steps to complete my ssl.com certificate order\z/ do |count|
  lambda{ |e|
    (is_capybara? ? page.all(:xpath, e) :
      @browser.elements_by_xpath(e)).count.should eql(count.to_i)
  } .call("//div[@id='form_progress_indicator']/ul/li")
end

Then /\A(?:he|she|I) should see certificate order receipt recipients\z/ do
  @browser.text.should include(@current_user.ssl_account
      .cached_certificate_orders.last.receipt_recipients.join(', '))
end

Then /\A(?:he|she|I) should see certificate order confirmation recipients\z/ do
  @browser.text.should include(@current_user.ssl_account
      .cached_certificate_orders.last.confirmation_recipients.join(', '))
end

Then /\A(?:he|she|I) should see processed certificates recipients\z/ do
  @browser.text.should include(@current_user.ssl_account
      .cached_certificate_orders.last.processed_recipients.join(', '))
end

Then /\A(?:he|she|I) should be (?:directed to\s|at\s)the new certificate order path\z/ do
  @browser.url.should include(@current_user.ssl_account
      .certificate_orders.last.ref)
end

When /\A(?:he|she|I) request domain control validation be sent during checkout\z/ do
  @domain_control_validation_count = DomainControlValidation.count
  visit(new_certificate_order_validation_path(@user.ssl_account.cached_certificate_orders.last))
  find('#upload_files').click
end

When /\A(?:he|she|I) request domain control validation from (\S+)\z/ do |email|
  @domain_control_validation_count = DomainControlValidation.count
  request_dcv_from_email(@user.ssl_account.cached_certificate_orders.last, email)
end

When /\A(?:he|she|I) forward domain control validation request to (\S+)\z/ do |email|
  @domain_control_validation_count = DomainControlValidation.count
  visit(other_party_validation_request_path(@other_party_validation_request.identifier))
  choose 'refer_to_others_true'
  fill_in 'other_party_validation_request_email_addresses', with: email
  click_on 'send request'
end

Then /\Aa domain control validation request should be sent\z/ do
  DomainControlValidation.count.should eql(@domain_control_validation_count + 1)
  dcv = DomainControlValidation.last
  page.should have_content(dcv.email_address)
  page.should have_content(dcv.sent_at.strftime('%b %d, %Y %R'))
end

When /\A(\S+) received a domain control validation request from (\S+)\z/ do |recipient, sender|
  validation_provider = User.find_by_login(recipient) ? User.find_by_login(recipient).email : recipient
  user = User.find_by_login(sender)
  @other_party_validation_request = FactoryGirl.create(:other_party_validation_request, user: user,
                                                                                        other_party_requestable: @certificate_order, email_addresses: validation_provider)
end

When /\A(\S+) attempts? to supply domain control validation\z/ do |_user|
  visit(other_party_validation_request_path(@other_party_validation_request.identifier))
end

def request_dcv_from_email(co, email)
  if co.new?
    visit(new_certificate_order_validation_path(co))
    choose 'refer_to_others_true'
    fill_in 'email_addresses', with: email
    find('#upload_files').click
  elsif co.paid?
    visit(edit_certificate_order_validation_path(co))
    choose 'refer_to_others_true'
    fill_in 'other_party_validation_request_email_addresses', with: email
    click_on 'send request'
  end
end

When /\A(\S+) sends? domain control validation verification\z/ do |_user|
  visit(other_party_validation_request_path(@other_party_validation_request.identifier))
  click_on 'send verification'
end

Then /\Adomain control validation confirmation should appear\z/ do
  page.should have_content("Validation email sent to #{find('#domain_control_validation_email').value}")
end

Then /\Adomain control validation request should be created\z/ do
  DomainControlValidation.last.email_address.should == find('#domain_control_validation_email').value
end

When /\AI get a (\S+) ssl certificate\z/ do |_product|
  visit buy_certificate_url
end
