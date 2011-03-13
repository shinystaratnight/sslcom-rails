Given /^(?:he|she|I) buys? a ['"]([^'"]*)['"] ['"]([^'"]*)['"] year certificate using csr ['"]([^'"]*)['"]$/ do |type, duration, csr|
  csr = eval("@#{csr}").gsub(/\r\n/,"\n")
  When "he goes to the '#{type}' certificate buy page"
  Then "he should be at step '1' of '4'"
  When "he fills the 'text_field' having attribute 'id' == 'signing_request' with", csr
    And "he selects '1' as 'server_software'"
    And "he clicks the 'radio' with '#{duration}' 'value'"
  @browser.button(:src, /next_bl\.gif/).click
end

Given /^(?:his|her|my)(?: shopping)? cart is empty$/ do
  @browser.goto APP_URL + show_cart_orders_path
  @browser.span(:id, 'clear_cart').click if
    @browser.span(:id, 'clear_cart').exists?
end

Given /^the following non-wildcard signed certificate exists$/ do |pystring|
  @signed_certificate = pystring
end

Given /^there is an open certificate order with ref number ['"]([^'"]*)['"]$/ do |ref|
  without_access_control do
    @current_order = CertificateOrder.find_by_ref(ref)
    @current_order.should_not be_nil
  end
end

Given /^there is a processed certificate order with ref number ['"]([^'"]*)['"]$/ do |ref|
  without_access_control do
    co = CertificateOrder.find_by_ref(ref)
    co.certificate_content.csr.signed_certificate = SignedCertificate.new(:body=>@lobby_sb_betsoftgaming_com_signed_cert)
    co.certificate_content.csr.signed_certificate.save
  end
end

Given /^['"](user .+?)['"]'s expiration trigger is set to ['"]([^'"]*)['"] ['"]([^'"]*)['"]$/ do |user,days,order|
  user.ssl_account.preferred_reminder_notice_triggers = days.to_i, order.to_i
  user.ssl_account.save
end

Given /^certificate order ['"]([^'"]*)['"] does not have a signed certificate$/ do |cert|
  without_access_control do
    co = CertificateOrder.find_by_ref(cert)
    co.certificate_content.csr.signed_certificate.destroy unless
      co.certificate_content.csr.signed_certificate.blank?
    co.certificate_content.csr.signed_certificate.should be_blank
  end
end

Given /^(?:his|her|my) reseller account has ['"]([^'"]*)['"] available$/ do |amount|
  without_access_control do
    @current_user.ssl_account.funded_account.update_attribute(:cents, amount.gsub(/[^\d\.]/,'').to_i*100)
  end
end

When /^(?:he|she|I) add(?:s)? a ['"]([^'"]*)['"] year ['"]([^'"]*)['"] ssl certificate to the cart$/ do |duration, type|
  When "he goes to the '#{type}' certificate buy page"
    And "he clicks the 'radio' with 'certificate_order_has_csr_false' 'id'"
    And "he clicks the 'radio' with '#{duration}' 'value'"
  @browser.button(:src, /next_bl\.gif/).click
end

When /^(?:he|she|I) add(?:s)? a ['"]([^'"]*)['"] year ['"]([^'"]*)['"] ssl certificate with domains ['"]([^'"]*)['"] to the cart$/ do |duration, type, domains|
  When "he goes to the '#{type}' certificate buy page"
    And "he clicks the 'radio' with 'certificate_order_has_csr_false' 'id'"
    And "he fills the 'text_field' having attribute 'name' == 'signing_request' with", domains
    And "he clicks the 'radio' with '#{duration}' 'value'"
  @browser.button(:src, /next_bl\.gif/).click
end

When /^(?:he|she|I) check(?:s)?out$/ do
  @browser.goto APP_URL + new_order_path
end

When /^(?:he|she|I) go(?:es)? to the ['"]([^'"]*)['"] certificate buy page$/ do |type|
  @browser.goto APP_URL + buy_certificate_path(type)
end

When /^(?:he|she|I) applies the order to the reseller account$/ do
  without_access_control do
    lambda{
      @browser.button(:src, /next_bl\.gif/).click
    }.should change {User.find_by_login(@current_user.login).ssl_account.funded_account.cents}.
    by(-@current_user.ssl_account.certificate_orders.last.amount)
  end
end

When /^(?:he|she|I) clicks the link to the current certificate order in progress$/ do
  co = @current_order || @current_user.ssl_account.certificate_orders.last
  @browser.link(:href, Regexp.new(certificate_order_path(co.ref))).click
end

When /^(?:he|she|I) go(?:es)? to the certificate order page for ['"]([^'"]*)['"]$/ do |ref|
  @browser.goto APP_URL + certificate_order_path(ref)
end

When /^certificate order ['"]([^'"]*)['"] is expiring in ['"]([^'"]*)['"]$/ do |ref, days|
  without_access_control do
    co = CertificateOrder.find_by_ref(ref)
    co.certificate_content.csr.signed_certificate.update_attribute :expiration_date, days.to_i.days.from_now
  end
end

When /^(?:he|she|I) fills in the applicant information using$/ do |table|
  fields = (defined? table.hashes) ? table.hashes : [table]
  fields.each do |field|
    @browser.text_field(:id, Regexp.new("department")).value = field["department"]
    @browser.text_field(:id, Regexp.new("po_box")).value = field["po_box"]
    @browser.text_field(:id, Regexp.new("address1")).value = field["address1"]
    @browser.text_field(:id, Regexp.new("postal_code")).value = field["postal_code"]
  end
end

When /^(?:he|she|I) submits? ['"]([^'"]*)['"] as the signed certificate$/ do |cert|
  @browser.text_field(:id, 'signed_certificate_body').value = cert
  @browser.startClicker('OK')
  @browser.button(:class, 'submit_signed_certificate').click_no_wait
  #@browser.get_popup_text.should include('invalid')
  #p.should include('valid')
end

When /^(?:he|she|I) (re)?submits? the variable ['"]([^'"]*)['"] as the signed certificate$/ do |resubmit,cert|
  @browser.text_field(:id, 'signed_certificate_body').value = eval("#{cert}").gsub(/\r\n/,"\n")
  @browser.startClicker('OK') if resubmit
  @browser.button(:class, 'submit_signed_certificate').click
  #give a chance for the fields to be updated
  sleep 5
end

When /^(?:he|she|I) clicks? the action link for the currently displayed order$/ do
  co = @current_order || @current_user.ssl_account.certificate_orders.last
  @browser.link(:href, Regexp.new(edit_certificate_order_path(co.ref))).click
end

When /^(?:he|she|I) enters? (?:his|her|my) new user information$/ do |table|
  profiles = (defined? table.hashes) ? table.hashes : [table]
  profiles.each do |profile|
    @browser.text_field(:id, "user_login").value = profile["login"]
    @browser.text_field(:id, "user_email").value = profile["email"]
    @browser.text_field(:id, "user_password").value = profile["password"]
    @browser.text_field(:id, "user_password_confirmation").value =
      profile["confirm"]
  end
end

When /^(?:he|she|I) add an ssl certificate to the cart$/ do |table|
  @order_total=0
  profiles = (defined? table.hashes) ? table.hashes : [table]
  profiles.each do |profile|
    if profile['domains'].blank?
      When "I add a '#{profile['years']}' year '#{profile['product']}' ssl certificate to the cart"
    else
      When "I add a '#{profile['years']}' year '#{profile['product']}' ssl certificate with domains '#{profile['domains']}' to the cart"
    end
    @order_total+=profile['price'].to_f
  end
end

Then /^the order amount displayed should be the same as the cart amount$/ do
  Then "I should see '#{@order_total}'"
#    And "I should see '#{@order_total}' in the 'input' with attribute 'id' == 'order_amount'"
end

Then /^(?:he|she|I) should see a popup containing ['"]([^'"]*)['"]$/ do |text|
  @browser.get_popup_text.should include(text)
end

Then /^there should ['"]([^'"]*)['"] be an (expiring|expired) indicator$/ do |be_or_not, status|
  expected_class = (status=='expiring')? 'expiration_warning' : 'attention'
  unless be_or_not=='not'
    @browser.elements_by_xpath("//td[@class='#{expected_class}']/span[@class='expires_on']").should_not be_empty
  end
end

Then /^(?:he|she|I) should see line items for this order$/ do
  @browser.text.should include(order_line_items(@current_user.ssl_account.certificate_orders.last))
end

Then /^(?:her|his|my) cart should be empty$/ do
  @browser.goto APP_URL + show_cart_orders_path
  Then "I should see '0.00'"
end

Then /^the certificate content fields should (?:remain the same as|be updated with) ['"]([^'"]*)['"] fields$/ do |cert|
  sc=SignedCertificate.new(:body=>eval("#{cert}"))
  @browser.text.should include(sc.common_name)
  @browser.text.should include(sc.organization)
  @browser.text.should include(sc.organization_unit) unless sc.organization_unit.blank?
  @browser.text.should include(sc.state) unless sc.state.blank?
  @browser.text.should include(sc.locality) unless sc.locality.blank?
  @browser.text.should include(sc.country)
  @browser.text.should include(sc.expiration_date.strftime("%b %d, %Y"))
  @browser.text.should include("submitted on "+Date.today.strftime("%b %d, %Y"))
end

Then /^(?:he|she|I) ['"]([^'"]*)['"] authorized to ['"]([^'"]*)['"] the ['"]([^'"]*)['"] ['"]([^'"]*)['"] object$/ do |permission, action, id, element|
  case action
  when /have on the page/
    should_or_not = (permission=='is')? :should_not : :should
    @browser.send(element.to_sym, "id", id).send(should_or_not, raise_error)
  end
end

Then /^(?:he|she|I) should be at step ['"]([^'"]*)['"] of ['"]([^'"]*)['"]$/ do |index, count|
  @browser.elements_by_xpath("//li[@id='selected']").first.text.should include(index+" ")
  @browser.elements_by_xpath("//div[@id='form_progress_indicator']/ul/li").count.should eql(count.to_i)
end

Then /^(?:he|she|I) should see certificate order receipt recipients$/ do
  @browser.text.should include(@current_user.ssl_account.
      certificate_orders.last.receipt_recipients.join(", "))
end

Then /^(?:he|she|I) should see certificate order confirmation recipients$/ do
  @browser.text.should include(@current_user.ssl_account.
      certificate_orders.last.confirmation_recipients.join(", "))
end

Then /^(?:he|she|I) should see processed certificates recipients$/ do
  @browser.text.should include(@current_user.ssl_account.
      certificate_orders.last.processed_recipients.join(", "))
end

Then /^(?:he|she|I) should be (?:directed to\s|at\s)the new certificate order path$/ do
  @browser.url.should include(@current_user.ssl_account.
      certificate_orders.last.ref)
end