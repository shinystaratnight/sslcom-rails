# frozen_string_literal: true

module Pagable
  extend ActiveSupport::Concern

  cattr_accessor :per_page

  included do
    # will_paginate
    @@per_page = 10
  end
end
