module AuthenticationHelpers
  def as_user(user)
    visit '/'
    Capybara.reset_sessions!
    visit login_path
    fill_in 'user_session_login', with: user.login
    fill_in 'user_session_password', with: user.password
    find('#btn_login').click
    yield

    visit logout_path
  end

  def submit_payment_information
    input_payment_information
    find('.order_next').click
  end

  def input_payment_information
    bp = attributes_for(:billing_profile)
    fill_in :billing_profile_first_name, with: bp[:first_name]
    fill_in :billing_profile_last_name, with: bp[:last_name]
    fill_in :billing_profile_address_1, with: bp[:address_1]
    fill_in :billing_profile_city, with: bp[:city]
    fill_in :billing_profile_state, with: bp[:state]
    fill_in :billing_profile_postal_code, with: bp[:postal_code]
    fill_in :billing_profile_phone, with: bp[:phone]
    fill_in :billing_profile_card_number, with: bp[:card_number]
    fill_in :billing_profile_security_code, with: bp[:security_code]
    within '#billing_profile_expiration_year' do
      all('option')[2].select_option
    end
  end
end
