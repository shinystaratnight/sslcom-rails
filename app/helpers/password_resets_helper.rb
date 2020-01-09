# frozen_string_literal: true

module PasswordResetsHelper
  def submit_button_class
    Rails.env.production? ? 'password_resets_btn hidden' : 'password_resets_btn'
  end
end
