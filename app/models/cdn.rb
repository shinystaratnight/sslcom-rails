# frozen_string_literal: true

class Cdn < ApplicationRecord
  belongs_to :ssl_account
  belongs_to :certificate_order
end
