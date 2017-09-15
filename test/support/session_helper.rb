module SessionHelper
  def login_as(user, cookies=nil)
    # User Login through Authlogic and Declarative Authorization
    UserSession.create(user, true)
    Authorization.current_user = user
    unless cookies.nil?
      # selenium requires to load page before cookies can be set
      visit new_user_session_path
      set_user_credentials_cookie(cookies)
    end
  end

  def login_as_from_ui(user, cookies=nil)
    # User Login through User Interface
    visit new_user_session_path
    set_user_credentials_cookie(cookies) unless cookies.nil?
    fill_in 'user_session_login',    with: user.login
    fill_in 'user_session_password', with: user.password
    find('input[alt="submit"]').click
  end
  
  def logged_as(user)
    # Using rack directly
    page.set_rack_session('user_credentials' => user.persistence_token)
  end

  def disable_authorization
    Authorization.ignore_access_control(true)
  end

  def set_user_credentials_cookie(cookie_hash)
    Capybara.current_session.driver.browser.manage.add_cookie(
      {name: 'user_credentials'}.merge(cookie_hash.first[1])
    )
  end

  def delete_all_cookies
    Capybara.current_session.driver.browser.manage.delete_all_cookies
  end

  def fill_in_cert_registrant
    registrant_id = 'certificate_order_certificate_contents_attributes_0_registrant_attributes'
    fill_in "#{registrant_id}_company_name", with: 'EZOPS Inc'
    fill_in "#{registrant_id}_address1",     with: '123 H St.'
    fill_in "#{registrant_id}_city",         with: 'Houston'
    fill_in "#{registrant_id}_state",        with: 'TX'
    fill_in "#{registrant_id}_postal_code",  with: '12345'
    find('input[alt="edit ssl certificate order"]').click
  end

  def fill_in_cert_contacts
    contacts_id = 'certificate_content_certificate_contacts_attributes_0'
    fill_in "#{contacts_id}_first_name", with: 'first'
    fill_in "#{contacts_id}_last_name",  with: 'last'
    fill_in "#{contacts_id}_email",      with: 'test_contact@domain.com'
    fill_in "#{contacts_id}_phone",      with: '1233334444'
    find('input[alt="Bl submit button"]').click
  end

  def update_cookie(cookie, user)
    value = "#{user.persistence_token}::#{user.send(user.class.primary_key)}"
    cookie.to_h['user_credentials'].merge!(value: value)
    cookie
  end

  def paypal_login
    email    = ENV.fetch('PAYPAL_TEST_BUYER_EMAIL')
    password = ENV.fetch('PAYPAL_TEST_BUYER_PASSWORD')
    sleep 5                          # Let Paypal login page load
    if first('#login_email')         # Older Paypal login view
      fill_in 'login_email',    with: email
      fill_in 'login_password', with: password
      click_button 'Log In'
      sleep 7                        # Let Paypal load/generate preview page
      find('#continue').click
    else
      if first('iframe')
        within_frame find('iframe') do # Newer Paypal login view
          fill_in 'email',    with: email
          fill_in 'password', with: password
          click_button 'Log In'
          sleep 8                      # Let Paypal load/generate preview page
        end
      end
      first('#continue') ? find('#continue').click : find('#confirmButtonTop').click
    end
    sleep 7                          # Let Paypal process transaction and exit/re-route
  end
end
