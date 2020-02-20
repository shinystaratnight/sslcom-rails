# frozen_string_literal: true

module Concerns
  module CertificateContent
    extend ActiveSupport::User

    included do
      PASSWORD_SPECIAL_CHARS = '~`!@#\$%^&*()-+={}[]|;:"<>,./?'
      LOGIN = /\A[a-zA-Z0-9_][a-zA-Z0-9\.+\-_@ ]+\z/.freeze
    end
  end
end
