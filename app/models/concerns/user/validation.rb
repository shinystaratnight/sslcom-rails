# frozen_string_literal: true

module Concerns
  module User
    module Validation
      extend ActiveSupport::Concern

      PASSWORD_SPECIAL_CHARS = '~`!@#\$%^&*()-+={}[]|;:"<>,./?'
      LOGIN = /\A[a-zA-Z0-9_][a-zA-Z0-9\.+\-_@ ]+\z/.freeze

      included do
        validates :email, email: true, uniqueness: true, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, on: :create }

        validates :password, format: {
          with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[\W]).{8,}\z/, if: :validate_password?,
          message: "must be at least 8 characters long and include at least 1 of each of the following: uppercase, lowercase, number and special character such as #{PASSWORD_SPECIAL_CHARS}"
        }
        validates :login, format: { with: LOGIN, message: 'shit aint right' }, if: :login_changed?
        validates :login, uniqueness: { case_sensitive: false }
        validates :login, length: { minimum: 3 }, if: :login_changed?
      end
    end
  end
end
