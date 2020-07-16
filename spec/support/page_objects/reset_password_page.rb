class ResetPasswordPage < SitePrism::Page
  set_url '/password_resets/new'

  element :login, '#login'
  element :email, '#email'
  element :submit, '.password_resets_btn'

  expected_elements :login, :email, :submit
end