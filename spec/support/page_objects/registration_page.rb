class RegistrationPage < SitePrism::Page
  set_url '/users/new'

  element :login, '#user_login'
  element :email, '#user_email'
  element :password, '#user_password'
  element :password_confirmation, '#user_password_confirmation'
  element :terms_of_service, '#tos'
  element :register, '#next_submit'

  expected_elements :login, :email, :password, :password_confirmation, :terms_of_service, :register
end
